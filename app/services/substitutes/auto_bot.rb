module Substitutes
  class AutoBot < ApplicationService
    attr_reader :match_lineup, :preview

    def initialize(match_lineup, preview: false)
      @match_lineup = match_lineup
      @preview = preview
    end

    def self.for_round(round, preview: true)
      round.tours.each do |tour|
        tour.autobot(preview: preview)
      end
    end

    def call
      return [] if main_players.empty? || bench_players.empty?

      assignments, = TieredMatcher.call(build_grid)

      lineup_substitutes = apply(assignments)

      match_lineup.update(substitutes: lineup_substitutes.to_json) if preview

      lineup_substitutes
    end

    private

    def apply(assignments)
      MatchPlayer.transaction do
        assignments.map do |row, col, _|
          out_mp = main_players[row]
          in_mp  = bench_players[col]

          Substitutes::Creator.call(out_mp.id, in_mp.id, 'autobot') unless preview

          { out: ui_string(out_mp), in: ui_string(in_mp) }
        end
      end
    end

    def build_grid
      main_players.map do |mp|
        bench_players.map do |bp|
          next 'X' unless (mp.available_positions & bp.position_names).any?

          Scores::PositionMalus::Counter.call(mp.real_position, bp.position_names)
        end
      end
    end

    def all_match_players
      @all_match_players ||= match_lineup.match_players.to_a
    end

    def main_players
      @main_players ||= all_match_players.select { |mp| mp.real_position.present? && mp.not_played? }
    end

    def bench_players
      @bench_players ||= all_match_players.select { |mp| mp.real_position.nil? && !mp.not_in_squad? && mp.score.positive? }
    end

    def ui_string(match_player)
      match_player.player.full_name_with_positions
    end
  end
end
