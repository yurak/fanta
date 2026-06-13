module Scores
  module Injectors
    class BaseMatch < ApplicationService
      attr_reader :match

      DEFAULT_SCORE = 6

      def initialize(match)
        @match = match
      end

      def call
        return unless match.page_url
        return unless match_finished?
        return unless players_data_ready?

        match.update(host_score: host_result, guest_score: guest_result)

        update_round_players

        audit_missed_players(players_hash)
      end

      private

      def update_round_players; end

      def round_players
        @round_players ||= match.tournament_round.round_players.includes(player: :positions)
      end

      def update_round_player(_round_player, _team_hash, _team_missed_goals)
        raise NoMethodError, 'This source is not supported'
      end

      def round_player_params(round_player, player_data, team_missed_goals)
        return { score: rating(player_data), in_squad: true } if round_player.manual_lock

        full_player_hash(round_player, player_data, team_missed_goals)
      end

      def full_player_hash(_round_player, _data, _team_missed_goals)
        raise NoMethodError, 'This source is not supported'
      end

      def stat_value(player_data, key)
        player_data[key] || 0
      end

      def rating(player_data)
        return DEFAULT_SCORE if player_data[:rating].to_f.zero? && player_data[:played_minutes]&.positive?

        player_data[:rating].to_f.round(1)
      end

      def cleansheet?(round_player, team_missed_goals, played_minutes)
        played_minutes.to_i >= MatchPlayer::MIN_PLAYED_MINUTES_FOR_CS &&
          team_missed_goals.zero? &&
          (round_player.position_names & Position::CLEANSHEET_ZONE).present?
      end

      def missed_goals(round_player, team_missed_goals)
        return 0 if round_player.position_names.exclude?(Position::GOALKEEPER)

        team_missed_goals
      end

      def audit_missed_players(players)
        match.update(missed_players_data: players)
        Audit::CsvWriter.call(match, players)
      end

      def players_hash
        {}
      end

      def match_finished?
        raise NoMethodError, 'This source is not supported'
      end

      def players_data_ready?
        true
      end

      def host_result
        raise NoMethodError, 'This source is not supported'
      end

      def guest_result
        raise NoMethodError, 'This source is not supported'
      end
    end
  end
end
