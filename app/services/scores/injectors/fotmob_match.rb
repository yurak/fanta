module Scores
  module Injectors
    class FotmobMatch < BaseMatch
      # FOTMOB_MATCH_URL = 'https://www.fotmob.com/match/'.freeze
      FOTMOB_MATCH_URL = 'https://www.fotmob.com/api/matchDetails?matchId='.freeze

      private

      def update_round_players
        if match.tournament_round.tournament.national?
          round_players.by_national_team(match.host_team_id).each { |rp| update_round_player(rp, host_scores_hash, guest_result) }
          round_players.by_national_team(match.guest_team_id).each { |rp| update_round_player(rp, host_scores_hash, host_result) }
        else
          round_players.by_club(match.host_club_id).each { |rp| update_round_player(rp, host_scores_hash, guest_result) }
          round_players.by_club(match.guest_club_id).each { |rp| update_round_player(rp, host_scores_hash, host_result) }
        end
      end

      def update_round_player(round_player, team_hash, team_missed_goals)
        player_data = team_hash[round_player.fotmob_id]
        return unless player_data

        round_player.update(round_player_params(round_player, player_data, team_missed_goals))

        team_hash.except!(round_player.fotmob_id)
      end

      def full_player_hash(round_player, data, team_missed_goals)
        # Supported params:
        # rating goal assist yellow_card red_card missed_goals own_goal
        # saves failed_penalty caught_penalty conceded_penalty penalties_won scored_penalty
        {
          score: rating(data), goals: stat_value(data, :goals), assists: stat_value(data, :assists),
          cleansheet: cleansheet?(round_player, team_missed_goals.to_i, data[:played_minutes]),
          scored_penalty: stat_value(data, :scored_penalty), caught_penalty: stat_value(data, :caught_penalty),
          failed_penalty: stat_value(data, :failed_penalty), missed_goals: stat_value(data, :missed_goals),
          own_goals: stat_value(data, :own_goals), saves: stat_value(data, :saves),
          played_minutes: stat_value(data, :played_minutes), yellow_card: data[:yellow_card], red_card: data[:red_card],
          conceded_penalty: conceded_penalty(data), penalties_won: stat_value(data, :penalties_won)
        }
      end

      def conceded_penalty(player_data)
        conceded_penalty = player_data[:conceded_penalty] || 0
        conceded_penalty = player_data[:penalty_missed_goals] if player_data[:penalty_missed_goals]&.positive?
        conceded_penalty
      end

      def host_scores_hash
        @host_scores_hash ||= Scores::Injectors::FotmobPlayersData.call(match_data['content'])
      end

      def match_finished?
        (status['started'] || status['awarded']) && status['finished']
      end

      def status
        return {} unless match_data['header']

        @status ||= match_data['header']['status']
      end

      def result
        status['scoreStr'].split(' - ')
      end

      def host_result
        @host_result ||= result[0]
      end

      def guest_result
        @guest_result ||= result[1]
      end

      ## API version
      def match_data
        @match_data ||= JSON.parse(html_page)
      end

      def html_page
        @html_page ||= Nokogiri::HTML(request)
      end

      def request
        RestClient.get("#{FOTMOB_MATCH_URL}#{match.source_match_id}")
      end

      ## Web parsing version
      # def match_data
      #   @match_data ||= JSON.parse(html_page)['props']['pageProps']['content']['matchFacts']['data']
      # end
      #
      # def html_page
      #   @html_page ||= Nokogiri::HTML(request).css('#__NEXT_DATA__').text
      # end
    end
  end
end
