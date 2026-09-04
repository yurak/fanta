module Scores
  module Injectors
    class BaseMatch < ApplicationService
      attr_reader :match

      DEFAULT_SCORE = 6
      FULL_MATCH_MINUTES = 90

      def initialize(match, run_mode: :final)
        @match = match
        @run_mode = run_mode
      end

      def call
        return false unless match.page_url

        if @run_mode == :schedule
          refresh_schedule
        elsif processable?
          update_match if match_writable?
          if players_data_ready?
            update_round_players
            audit_missed_players(players_hash) if match_finished?
          end
        end

        data_available?
      end

      def data_available?
        true
      end

      private

      def update_match
        match.update(host_score: host_result, guest_score: guest_result, status: match_state,
                     live_minute: live_minute, **kickoff_attributes)
      end

      def match_writable?
        match_live? || players_data_ready?
      end

      def live_minute
        nil
      end

      def refresh_schedule
        attributes = kickoff_attributes
        match.update(attributes) if attributes.present?
      end

      def processable?
        return match_finished? if @run_mode == :final

        match_finished? || match_live?
      end

      def match_state
        match_finished? ? :finished : :live
      end

      def match_live?
        false
      end

      # { date:, time: } parsed from the source, or {} when unknown — overridden per source
      def kickoff_attributes
        {}
      end

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

      def cleansheet?(round_player, team_missed_goals, played_minutes, timing: nil)
        return false if played_minutes.to_i < MatchPlayer::MIN_PLAYED_MINUTES_FOR_CS
        return false unless round_player.position_names.intersect?(Position::CLEANSHEET_ZONE)

        return no_goals_while_on_pitch?(timing) if timing && played_minutes.to_i < FULL_MATCH_MINUTES

        team_missed_goals.zero?
      end

      def no_goals_while_on_pitch?(timing)
        on_minute = timing[:on_minute].to_i # 0 for a starter
        off_minute = timing[:off_minute] || Float::INFINITY # played to the final whistle

        timing[:conceded_minutes].none? { |minute| minute > on_minute && minute <= off_minute }
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
