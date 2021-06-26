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

        update_round_players
      end

      private

      def update_round_players
        if match.tournament_round.tournament.national?
          round_players.by_national_team(match.host_team.id).each { |rp| update_round_player(rp, scores_data[0], result[1]) }
          round_players.by_national_team(match.guest_team.id).each { |rp| update_round_player(rp, scores_data[1], result[0]) }
        else
          round_players.by_club(match.host_club.id).each { |rp| update_round_player(rp, scores_data[0], result[1]) }
          round_players.by_club(match.guest_club.id).each { |rp| update_round_player(rp, scores_data[1], result[0]) }
        end
      end

      def round_players
        @round_players ||= match.tournament_round.round_players
      end

      def update_round_player(round_player, team_hash, team_missed_goals)
        player_data = players_hash(team_hash)[round_player.pseudo_name.downcase]
        return unless player_data

        round_player.update(
          score: player_data[:rating].to_f,
          cleansheet: cleansheet?(round_player, team_missed_goals.to_i),
          goals: player_data[:goals] || 0,
          assists: player_data[:assists] || 0,
          failed_penalty: player_data[:failed_penalty] || 0,
          missed_goals: player_data[:missed_goals] || 0,
          own_goals: player_data[:own_goals] || 0,
          yellow_card: player_data[:yellow_card],
          red_card: player_data[:red_card]
        )
      end

      def players_hash(team)
        scores_hash = team['players'].each_with_object({}) do |line, hash|
          line.each do |player_data|
            next unless player_data['rating']['num']

            hash[player_name(player_data)] = player_hash(player_data)
          end
        end

        team['bench'].each_with_object(scores_hash) do |player_data, hash|
          next unless player_data['rating'] && player_data['rating']['num']

          hash[player_name(player_data)] = player_hash(player_data)
        end
      end

      def player_hash(player_data)
        hash = { rating: player_data['rating']['num'], missed_goals: player_data['stats'][0]['Goals conceded']&.first }.compact

        return hash unless player_data['events']

        hash.merge!(
          {
            goals: player_data['events']['g'],
            assists: player_data['events']['as'],
            failed_penalty: player_data['events']['mp'],
            own_goals: player_data['events']['og'],
            yellow_card: card?(player_data['events']['yc']),
            red_card: card?(player_data['events']['ycrc']) || card?(player_data['events']['rc'])
          }
        )
      end

      def player_name(player_data)
        name = "#{player_data['name']['firstName']} #{player_data['name']['lastName']}"
        name.mb_chars.lstrip.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').downcase.to_s
      end

      def cleansheet?(round_player, team_missed_goals)
        return false if team_missed_goals.positive? || (round_player.position_names & Position::CLEANSHEET_ZONE).blank?

        true
      end

      def card?(card_value)
        return false if card_value.blank?

        card_value.positive?
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
