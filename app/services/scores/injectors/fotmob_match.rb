module Scores
  module Injectors
    class FotmobMatch < ApplicationService
      FOTMOB_MATCH_URL = 'https://www.fotmob.com/matchDetails?matchId='.freeze

      attr_reader :match

      def initialize(match:)
        @match = match
      end

      def call
        return unless match_finished?

        match.update(host_score: result[0], guest_score: result[1])

        if match.instance_of?(NationalMatch)
          update_national_round_players(match.host_team, scores_data[0])
          update_national_round_players(match.guest_team, scores_data[1])
        else
          update_club_round_players(match.host_club, scores_data[0])
          update_club_round_players(match.guest_club, scores_data[1])
        end
      end

      private

      def update_club_round_players(club, team_hash)
        match.tournament_round.round_players.by_club(club.id).each do |rp|
          player_data = players_hash(team_hash)[rp.pseudo_name.downcase]
          rp.update(score: player_data[:rating].to_f) if player_data
        end
      end

      def update_national_round_players(team, team_hash)
        match.tournament_round.round_players.by_national_team(team.id).each do |rp|
          player_data = players_hash(team_hash)[rp.pseudo_name.downcase]
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
        status['started'] && status['finished']
      end

      def result
        status['scoreStr'].split(' - ')
      end

      def status
        @status ||= match_data['header']['status']
      end

      def match_data
        @match_data ||= JSON.parse(request)
      end

      def request
        RestClient.get(match_url)
      end

      def match_url
        "#{FOTMOB_MATCH_URL}#{match.source_match_id}"
      end
    end
  end
end
