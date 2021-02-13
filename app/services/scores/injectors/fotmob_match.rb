module Scores
  module Injectors
    class FotmobMatch < ApplicationService
      attr_reader :match_url, :match

      def initialize(match:, match_url:)
        @match = match
        @match_url = match_url
      end

      def call
        return unless match_finished?

        match.update(host_score: result[0], guest_score: result[1])

        update_round_players(match.host_club, scores_data[0])
        update_round_players(match.guest_club, scores_data[1])
      end

      private

      def update_round_players(club, club_hash)
        match.tournament_round.round_players.by_club(club.id).each do |rp|
          player_data = players_hash(club_hash)[rp.pseudo_name.downcase]
          rp.update(score: player_data[:rating].to_f) if player_data
        end
      end

      def players_hash(team)
        scores_hash = team['players'].each_with_object({}) do |line, hash|
          line.each do |player_data|
            next unless player_data['rating']['num']

            hash[player_name(player_data)] = { rating: player_data['rating']['num'] }
          end
        end

        team['bench'].each_with_object(scores_hash) do |player_data, hash|
          next unless player_data['rating'] && player_data['rating']['num']

          hash[player_name(player_data)] = { rating: player_data['rating']['num'] }
        end
      end

      def player_name(player_data)
        name = "#{player_data['name']['firstName']} #{player_data['name']['lastName']}"
        name.mb_chars.lstrip.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').downcase.to_s
      end

      def scores_data
        match_data['content']['lineup']['lineup']
      end

      def match_finished?
        match_data['header']['status']['finished']
      end

      def result
        match_data['header']['status']['scoreStr'].split(' - ')
      end

      def match_data
        @match_data ||= JSON.parse(request)
      end

      def request
        RestClient.get(match_url)
      end
    end
  end
end
