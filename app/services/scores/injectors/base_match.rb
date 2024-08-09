module Scores
  module Injectors
    class BaseMatch < ApplicationService
      MIN_PLAYED_MINUTES_FOR_CS = 60

      attr_reader :match

      def initialize(match)
        @match = match
      end

      def call
        return unless match.source_match_id
        return unless match_finished?

        match.update(host_score: host_result, guest_score: guest_result)

        update_round_players

        Audit::CsvWriter.call(match, host_scores_hash, guest_scores_hash)
      end

      private

      def update_round_players
        if match.tournament_round.tournament.national?
          round_players.by_national_team(match.host_team_id).each { |rp| update_round_player(rp, host_scores_hash, guest_result) }
          round_players.by_national_team(match.guest_team_id).each { |rp| update_round_player(rp, guest_scores_hash, host_result) }
        else
          round_players.by_club(match.host_club_id).each { |rp| update_round_player(rp, host_scores_hash, guest_result) }
          round_players.by_club(match.guest_club_id).each { |rp| update_round_player(rp, guest_scores_hash, host_result) }
        end
      end

      def round_players
        @round_players ||= match.tournament_round.round_players
      end

      def update_round_player(_round_player, _team_hash, _team_missed_goals)
        raise NoMethodError, 'This source is not supported'
      end

      def round_player_params(round_player, player_data, team_missed_goals)
        return { score: rating(player_data) } if round_player.manual_lock

        full_player_hash(round_player, player_data, team_missed_goals)
      end

      def full_player_hash(_round_player, _data, _team_missed_goals)
        raise NoMethodError, 'This source is not supported'
      end

      def stat_value(player_data, key)
        player_data[key] || 0
      end

      def rating(player_data)
        return 6 if player_data[:rating].nil? && player_data[:played_minutes].positive?

        player_data[:rating].to_f.round(1)
      end

      def cleansheet?(round_player, team_missed_goals, played_minutes)
        return false if played_minutes < MIN_PLAYED_MINUTES_FOR_CS
        return false if team_missed_goals.positive?
        return false if (round_player.position_names & Position::CLEANSHEET_ZONE).blank?

        true
      end

      def missed_goals(round_player, team_missed_goals)
        return 0 if round_player.position_names.exclude?(Position::GOALKEEPER)

        team_missed_goals
      end

      def host_scores_hash
        raise NoMethodError, 'This source is not supported'
      end

      def guest_scores_hash
        raise NoMethodError, 'This source is not supported'
      end

      def match_finished?
        raise NoMethodError, 'This source is not supported'
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
