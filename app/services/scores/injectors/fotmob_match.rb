module Scores
  module Injectors
    class FotmobMatch < BaseMatch
      FOTMOB_MATCH_URL = 'https://www.fotmob.com'.freeze
      PENALTY_KEY = 'penalty'.freeze
      # FOTMOB_MATCH_URL = 'https://www.fotmob.com/api/matchDetails?matchId='.freeze

      USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
                   '(KHTML, like Gecko) Chrome/124.0 Safari/537.36'.freeze
      REQUEST_TIMEOUT = 15
      MAX_RETRIES = 2
      BACKOFF_SECONDS = 5
      TRANSIENT_ERRORS = [
        RestClient::ServerBrokeConnection, RestClient::Exceptions::Timeout,
        Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ETIMEDOUT, OpenSSL::SSL::SSLError, SocketError
      ].freeze

      def initialize(match, run_mode: :final, budget: Scores::ScrapeBudget.new)
        super(match, run_mode: run_mode)
        @budget = budget
      end

      def data_available?
        match_data.present?
      end

      def scrape_health_failure?
        match_data.blank? && @scrape_failure != :not_found
      end

      private

      def update_round_players
        if match.tournament_round.tournament.national?
          update_side(round_players.by_national_team(match.host_team_id), conceded_for(home: true))
          update_side(round_players.by_national_team(match.guest_team_id), conceded_for(home: false))
        else
          update_side(round_players.by_club(match.host_club_id), conceded_for(home: true))
          update_side(round_players.by_club(match.guest_club_id), conceded_for(home: false))
        end
      end

      def conceded_for(home:)
        {
          total: home ? guest_result : host_result,
          minutes: goal_minutes_conceded_by(home: home),
          penalty_minutes: penalty_minutes_conceded_by(home: home)
        }
      end

      def update_side(players, conceded)
        players.each { |round_player| update_round_player(round_player, conceded) }
      end

      def update_round_player(round_player, conceded)
        player_data = players_hash[round_player.fotmob_id]
        return unless player_data

        round_player.update(round_player_params(round_player, player_data, conceded))

        players_hash.except!(round_player.fotmob_id)
      end

      def round_player_params(round_player, player_data, conceded)
        return { score: rating(player_data), in_squad: true } if round_player.manual_lock

        full_player_hash(round_player, player_data, conceded)
      end

      def full_player_hash(round_player, data, conceded)
        # Supported params:
        # rating goal assist yellow_card red_card missed_goals missed_penalty own_goal
        # saves failed_penalty caught_penalty conceded_penalty penalties_won scored_penalty
        played_minutes = live_played_minutes(data)
        penalty_goals = missed_penalty(round_player, data, conceded[:penalty_minutes])
        {
          score: rating(data), goals: stat_value(data, :goals), assists: stat_value(data, :assists),
          cleansheet: cleansheet?(round_player, conceded[:total].to_i, played_minutes,
                                  timing: cleansheet_timing(data, conceded[:minutes])),
          scored_penalty: stat_value(data, :scored_penalty), caught_penalty: stat_value(data, :caught_penalty),
          failed_penalty: stat_value(data, :failed_penalty),
          missed_goals: missed_goals_without_penalties(data, penalty_goals), missed_penalty: penalty_goals,
          own_goals: stat_value(data, :own_goals), saves: stat_value(data, :saves),
          played_minutes: played_minutes, yellow_card: data[:yellow_card], red_card: data[:red_card],
          conceded_penalty: stat_value(data, :conceded_penalty), penalties_won: stat_value(data, :penalties_won),
          in_squad: true
        }
      end

      def missed_goals_without_penalties(data, penalty_goals)
        [stat_value(data, :missed_goals).to_i - penalty_goals, 0].max
      end

      def missed_penalty(round_player, data, penalty_minutes)
        return 0 unless round_player.position_names.include?(Position::GOALKEEPER)

        from_stats = stat_value(data, :penalty_missed_goals).to_i
        return from_stats if from_stats.positive?

        # A keeper who was on the pitch is not necessarily the one who was beaten: after a red card
        # his own sub-off is not in the events, so his window stays open to the end of the match.
        # What he actually conceded is the ceiling.
        [penalties_while_on_pitch(data, penalty_minutes), stat_value(data, :missed_goals).to_i].min
      end

      def penalties_while_on_pitch(data, penalty_minutes)
        on_minute = data[:sub_in_minute].to_i
        off_minute = data[:sub_out_minute] || Float::INFINITY

        penalty_minutes.count { |minute| minute > on_minute && minute <= off_minute }
      end

      def live_played_minutes(data)
        return 0 if @run_mode == :live

        stat_value(data, :played_minutes)
      end

      def cleansheet_timing(data, conceded_minutes)
        { on_minute: data[:sub_in_minute], off_minute: data[:sub_out_minute], conceded_minutes: conceded_minutes }
      end

      def goal_minutes_conceded_by(home:)
        goal_minutes(goal_events, home: home)
      end

      def penalty_minutes_conceded_by(home:)
        goal_minutes(goal_events.select { |event| event['goalDescriptionKey'] == PENALTY_KEY }, home: home)
      end

      def goal_minutes(events, home:)
        events.reject { |event| event['isHome'] == home }.map { |event| event['time'].to_i + event['overloadTime'].to_i }
      end

      def goal_events
        @goal_events ||= match_events.select { |event| event['type'] == 'Goal' && !event['isPenaltyShootoutEvent'] }
      end

      def match_events
        match_data.dig('content', 'matchFacts', 'events', 'events') || []
      end

      def players_hash
        @players_hash ||= Scores::Injectors::FotmobPlayersData.call(match_data['content'])
      end

      def players_data_ready?
        return players_hash.values.any? { |data| data[:rating].to_f.positive? } if @run_mode == :live

        players_hash.values.any? { |data| data[:played_minutes].to_i.positive? }
      end

      def match_finished?
        correct_round? && (status['started'] || status['awarded']) && status['finished']
      end

      def match_live?
        correct_round? && (status['started'] || status['awarded']) && !status['finished']
      end

      def live_minute
        return nil unless match_live?

        status.dig('liveTime', 'short').to_s[/\d+/]&.to_i
      end

      def kickoff_attributes
        return {} unless correct_round?
        return {} if status['matchDateTbd'] || status['utcTime'].blank?

        kickoff = DateTime.parse(status['utcTime']).utc
        { date: kickoff.strftime('%^b %e, %Y'), time: kickoff.strftime('%H:%M') }
      rescue ArgumentError
        {}
      end

      def correct_round?
        return true if match.tournament_round.tournament.skip_round_check?

        fetched_round_number == match.tournament_round.number
      end

      def fetched_round_number
        match_data.dig('general', 'leagueRoundName').to_i
      end

      def status
        @status ||= match_data.dig('header', 'status') || {}
      end

      def result
        @result ||= status['scoreStr'].split(' - ')
      end

      def host_result
        result[0]
      end

      def guest_result
        result[1]
      end

      def match_data
        return @match_data if defined?(@match_data)

        html = fetch_html
        @match_data = html ? JSON.parse(Nokogiri::HTML(html).css('#__NEXT_DATA__').text)['props']['pageProps'] : {}
      rescue JSON::ParserError, NoMethodError => e
        @scrape_failure = :health
        log_scrape_skip("parse error: #{e.message}")
        @match_data = {}
      end

      def fetch_html
        attempt = 0
        begin
          attempt += 1
          RestClient::Request.execute(method: :get, url: "#{FOTMOB_MATCH_URL}#{match.page_url}",
                                      headers: { user_agent: USER_AGENT }, timeout: REQUEST_TIMEOUT)
        rescue RestClient::ExceptionWithResponse, *TRANSIENT_ERRORS => e
          retry if retry_after_backoff?(e, attempt)

          @scrape_failure = scrape_failure_kind(e)
          log_scrape_skip(scrape_reason(e))
          nil
        end
      end

      def retry_after_backoff?(error, attempt)
        return false unless scrape_retriable?(error) && attempt <= MAX_RETRIES

        backoff = @budget.take(attempt * BACKOFF_SECONDS)
        return false unless backoff.positive?

        sleep(backoff)
        true
      end

      def scrape_failure_kind(error)
        return :not_found if error.is_a?(RestClient::ResourceNotFound)

        :health
      end

      def scrape_retriable?(error)
        return true unless error.is_a?(RestClient::ExceptionWithResponse)

        error.http_code.to_i >= 500
      end

      def scrape_reason(error)
        error.is_a?(RestClient::ExceptionWithResponse) ? "HTTP #{error.http_code}" : error.class.to_s
      end

      def log_scrape_skip(reason)
        Rails.logger.warn("[live-scores] FotMob scrape skipped for #{match.page_url}: #{reason}")
      end
    end
  end
end
