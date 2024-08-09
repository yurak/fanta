module Scores
  module Injectors
    class FotmobMatch < BaseMatch
      # FOTMOB_MATCH_URL = 'https://www.fotmob.com/match/'.freeze
      FOTMOB_MATCH_URL = 'https://www.fotmob.com/api/matchDetails?matchId='.freeze

      private

      def update_round_player(round_player, team_hash, team_missed_goals)
        player_data = team_hash[round_player.fotmob_id]
        return unless player_data

        round_player.update(round_player_params(round_player, player_data, team_missed_goals))

        team_hash.except!(round_player.fotmob_id)
      end

      def full_player_hash(round_player, data, team_missed_goals)
        # Supported params: rating goal assist yellow_card red_card missed_goals own_goal
        # Unsupported params: saves failed_penalty caught_penalty conceded_penalty penalties_won
        {
          score: rating(data), goals: stat_value(data, :goal), assists: stat_value(data, :assist),
          cleansheet: cleansheet?(round_player, team_missed_goals.to_i, data[:played_minutes]),
          missed_goals: missed_goals(round_player, team_missed_goals.to_i), own_goals: stat_value(data, :own_goal),
          played_minutes: stat_value(data, :played_minutes), yellow_card: data[:yellow_card], red_card: data[:red_card]
        }
      end

      def host_scores_hash
        @host_scores_hash ||= Scores::Injectors::FotmobPlayersData.call(match_data['content']['lineup2']['homeTeam'])
      end

      def guest_scores_hash
        @guest_scores_hash ||= Scores::Injectors::FotmobPlayersData.call(match_data['content']['lineup2']['awayTeam'])
      end

      def match_finished?
        (status['started'] || status['awarded']) && status['finished']
      end

      def status
        @status ||= match_data['header']['status']
      end

      def result
        status['scoreStr'].split(' - ')
      end

      def host_result
        @host_result ||= result[0]
      end

      def guest_result
        @guest_result ||= result[0]
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
