module Scores
  module Injectors
    class FotmobMatch < ApplicationService
      FOTMOB_MATCH_URL = 'https://www.fotmob.com/matchDetails?matchId='.freeze
      FOTMOB_MATCH_URL_NEW = 'https://www.fotmob.com/match/'.freeze
      MIN_PLAYED_MINUTES_FOR_CS = 60

      attr_reader :match

      def initialize(match:)
        @match = match
      end

      def call
        return unless match_finished?

        match.update(host_score: result[0], guest_score: result[1])

        update_round_players

        Audit::CsvWriter.call(match, host_scores_hash, guest_scores_hash)
      end

      private

      def update_round_players
        if match.tournament_round.tournament.national?
          round_players.by_national_team(match.host_team.id).each { |rp| update_round_player(rp, host_scores_hash, result[1]) }
          round_players.by_national_team(match.guest_team.id).each { |rp| update_round_player(rp, guest_scores_hash, result[0]) }
        else
          round_players.by_club(match.host_club.id).each { |rp| update_round_player(rp, host_scores_hash, result[1]) }
          round_players.by_club(match.guest_club.id).each { |rp| update_round_player(rp, guest_scores_hash, result[0]) }
        end
      end

      def round_players
        @round_players ||= match.tournament_round.round_players
      end

      def update_round_player(round_player, team_hash, team_missed_goals)
        player_data = team_hash[round_player.pseudo_name.downcase]
        return unless player_data

        if round_player.manual_lock
          round_player.update(score: player_data[:rating].to_f)
        else
          round_player.update(
            score: player_data[:rating].to_f, goals: player_data[:goals] || 0, assists: player_data[:assists] || 0,
            cleansheet: cleansheet?(round_player, team_missed_goals.to_i, player_data[:played_minutes]),
            failed_penalty: player_data[:failed_penalty] || 0, caught_penalty: player_data[:caught_penalty] || 0,
            missed_goals: player_data[:missed_goals] || 0, own_goals: player_data[:own_goals] || 0,
            played_minutes: player_data[:played_minutes] || 0, yellow_card: player_data[:yellow_card], red_card: player_data[:red_card]
          )
        end
        team_hash.except!(round_player.pseudo_name.downcase)
      end

      def players_hash(team)
        scores_hash = team['players'].each_with_object({}) do |line, hash|
          line.each do |player_data|
            next unless player_data.dig('rating', 'num')

            hash[player_name(player_data)] = player_hash(player_data)
          end
        end

        team['bench'].each_with_object(scores_hash) do |player_data, hash|
          next unless player_data.dig('rating', 'num')

          hash[player_name(player_data)] = player_hash(player_data)
        end
      end

      def player_hash(player_data)
        hash = {
          rating: player_data['rating']['num'],
          played_minutes: player_data['minutesPlayed']&.to_i,
          missed_goals: player_data['stats'][0]['stats']['Goals conceded']
        }.compact

        return hash unless player_data['events']

        hash.merge!(
          {
            goals: player_data['events']['g'], assists: player_data['events']['as'],
            caught_penalty: player_data['events']['savedPenalties'], failed_penalty: player_data['events']['mp'],
            own_goals: player_data['events']['og'],
            yellow_card: card?(player_data['events']['yc']),
            red_card: card?(player_data['events']['ycrc']) || card?(player_data['events']['rc'])
          }
        )
      end

      def player_name(player_data)
        name = "#{player_data['name']['firstName']} #{player_data['name']['lastName']}"
        name.lstrip.unicode_normalize(:nfd).gsub(/[^\x00-\x7F]/n, '').downcase.to_s
      end

      def cleansheet?(round_player, team_missed_goals, played_minutes)
        return false if played_minutes < MIN_PLAYED_MINUTES_FOR_CS
        return false if team_missed_goals.positive?
        return false if (round_player.position_names & Position::CLEANSHEET_ZONE).blank?

        true
      end

      def card?(card_value)
        return false if card_value.blank?

        card_value.positive?
      end

      def host_scores_hash
        @host_scores_hash ||= players_hash(match_data['content']['lineup']['lineup'][0])
      end

      def guest_scores_hash
        @guest_scores_hash ||= players_hash(match_data['content']['lineup']['lineup'][1])
      end

      def match_finished?
        status['started'] && status['finished']
      end

      def result
        status['scoreStr'].split(' - ')
      end

      def status
        @status ||= match_data['header']['status']
      end

      def match_data
        @match_data ||= new_api? ? JSON.parse(html_page)['props']['pageProps']['initialState']['matchFacts']['data'] : JSON.parse(request)
      end

      def html_page
        @html_page ||= Nokogiri::HTML(request).css('#__NEXT_DATA__').text
      end

      def request
        RestClient.get("#{fotmob_url}#{match.source_match_id}")
      end

      def fotmob_url
        new_api? ? FOTMOB_MATCH_URL_NEW : FOTMOB_MATCH_URL
      end

      def new_api?
        # TODO: add config variable to this service
        true
      end
    end
  end
end
