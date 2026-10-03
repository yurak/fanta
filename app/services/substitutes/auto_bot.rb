module Substitutes
  class AutoBot < ApplicationService
    attr_reader :match_lineup, :preview

    def initialize(match_lineup, preview: false)
      @match_lineup = match_lineup
      @preview = preview
    end

    def self.for_round(round, preview: true)
      round.tours.each_with_object({ lineups: 0, substitutes: 0, failures: [] }) do |tour, acc|
        results = tour.autobot(preview: preview)
        acc[:lineups] += results.size
        acc[:substitutes] += results.sum(&:size)
      rescue StandardError => e
        acc[:failures] << "tour #{tour.id}: #{e.class}: #{e.message}"
      end
    end

    def call
      pairs = preview ? planned_pairs : approved_pairs
      applied = preview ? pairs : commit(pairs)

      match_lineup.update(substitutes: applied.to_json)

      applied
    end

    private

    def planned_pairs
      return [] if main_players.empty? || bench_players.empty?

      assignments, = TieredMatcher.call(build_grid)

      assignments.map do |row, col, _|
        out_mp = main_players[row]
        in_mp = bench_players[col]

        { 'out_mp_id' => out_mp.id, 'in_mp_id' => in_mp.id, 'out' => ui_string(out_mp), 'in' => ui_string(in_mp) }
      end
    end

    def approved_pairs
      stored = match_lineup.substitutes_preview
      return planned_pairs unless stored.any? && stored.all? { |pair| pair['out_mp_id'] && pair['in_mp_id'] }

      stored
    end

    def commit(pairs)
      MatchPlayer.transaction do
        pairs.select { |pair| applied?(pair) }
      end
    end

    def applied?(pair)
      return true if Substitutes::Creator.call(pair['out_mp_id'], pair['in_mp_id'], 'autobot')

      Rails.logger.warn("[autobot] skipped lineup=#{match_lineup.id} out_mp=#{pair['out_mp_id']} " \
                        "in_mp=#{pair['in_mp_id']} reason=no_longer_valid")
      false
    end

    def build_grid
      main_players.map do |mp|
        bench_players.map do |bp|
          next 'X' unless mp.available_positions.intersect?(bp.position_names)

          Scores::PositionMalus::Counter.call(mp.real_position, bp.position_names)
        end
      end
    end

    def all_match_players
      @all_match_players ||= match_lineup.match_players.reorder(:id).to_a
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
