module Substitutes
  class TieredMatcher < ApplicationService
    TIERS = [0, Position::S_MALUS, Position::M_MALUS].freeze

    def initialize(grid)
      @grid = grid
      @m = grid.size
      @n = @m.positive? ? grid[0].size : 0
    end

    def call
      return [[], 0.0] if @m.zero? || @n.zero?

      prepare
      return [[], 0.0] if @eligible_rows.empty?

      @all_edges = build_all_edges

      TIERS.each_with_index do |tier, idx|
        tier_edges = build_edges_for(tier)

        @eligible_rows.each_with_index do |_r, i|
          next if @match_row[i] != -1

          augment(i, tier_edges, Array.new(@n, false))
        end

        lock_assigned_columns unless idx == TIERS.size - 1
      end

      report
    end

    private

    def prepare
      @eligible_rows = (0...@m).select { |r| @grid[r].any? { |v| v != 'X' } }
      @match_col = Array.new(@n, -1)
      @match_row = Array.new(@eligible_rows.size, -1)
      @locked_cols = Array.new(@n, false)
    end

    def build_edges_for(tier)
      @eligible_rows.map { |r| (0...@n).select { |c| @grid[r][c] == tier } }
    end

    def build_all_edges
      @eligible_rows.map { |r| (0...@n).reject { |c| @grid[r][c] == 'X' } }
    end

    def augment(idx, tier_edges, visited)
      tier_edges[idx].each do |c|
        next if @locked_cols[c] || visited[c]

        visited[c] = true

        next unless @match_col[c] == -1 || augment(@match_col[c], @all_edges, visited)

        @match_col[c] = idx
        @match_row[idx] = c
        return true
      end

      false
    end

    def lock_assigned_columns
      (0...@n).each { |c| @locked_cols[c] = true if @match_col[c] != -1 }
    end

    def report
      assignments = []
      total = 0.0

      @eligible_rows.each_with_index do |r, i|
        c = @match_row[i]
        next if c == -1

        v = @grid[r][c]
        assignments << [r, c, v.to_f]
        total += v.to_f
      end

      [assignments, total]
    end
  end
end
