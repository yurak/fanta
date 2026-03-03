module Substitutes
  class TieredMatcher < ApplicationService
    def initialize(grid)
      @grid = grid
      @m = grid.size
      @n = @m.positive? ? grid[0].size : 0
    end

    def call
      return [[], 0.0] if @m.zero? || @n.zero?

      prepare
      return [[], 0.0] if @eligible_rows.empty?

      # Phase 1: maximise zero-malus matches first (highest priority)
      @eligible_rows.each_with_index do |_r, i|
        augment_zero(i, Array.new(@n, false))
      end

      # Phase 2: maximise total matches without reducing zero-malus count.
      # Loops must stay separate — phase 1 must complete before phase 2 starts.
      # rubocop:disable Style/CombinableLoops
      @eligible_rows.each_with_index do |_r, i|
        next if @match_row[i] != -1

        augment_full(i, Array.new(@n, false), zero_only: false)
      end
      # rubocop:enable Style/CombinableLoops

      improve
      report
    end

    private

    def prepare
      @eligible_rows = (0...@m).select { |r| @grid[r].any? { |v| v != 'X' } }
      @all_edges = @eligible_rows.map do |r|
        (0...@n).reject { |c| @grid[r][c] == 'X' }
                .sort_by { |c| @grid[r][c] }
      end
      @zero_edges = @eligible_rows.map do |r|
        (0...@n).select { |c| @grid[r][c] == 0 } # rubocop:disable Style/NumericPredicate
      end
      @match_col = Array.new(@n, -1)
      @match_row = Array.new(@eligible_rows.size, -1)
    end

    # Phase 1: augment using zero-malus edges only
    def augment_zero(idx, visited)
      @zero_edges[idx].each do |c|
        next if visited[c]

        visited[c] = true

        next unless @match_col[c] == -1 || augment_zero(@match_col[c], visited)

        @match_col[c] = idx
        @match_row[idx] = c
        return true
      end

      false
    end

    # Phase 2: augment using all edges, preserving zero-malus count.
    # zero_only: true means this row was displaced from a zero-malus slot by a
    # non-zero edge — it may only escape via its own zero-malus edges (to avoid
    # reducing the total number of zero-malus matches).
    def augment_full(idx, visited, zero_only:)
      edges = zero_only ? @zero_edges[idx] : @all_edges[idx]

      edges.each do |c|
        next if visited[c]

        visited[c] = true

        val = @grid[@eligible_rows[idx]][c]
        # Non-zero edge taking a slot: displaced row must use zero-only escape
        next_zero_only = val != 0

        next unless @match_col[c] == -1 || augment_full(@match_col[c], visited, zero_only: next_zero_only)

        @match_col[c] = idx
        @match_row[idx] = c
        return true
      end

      false
    end

    def improve
      loop { break unless improve_pass }
    end

    def improve_pass
      @eligible_rows.each_with_index do |r, i|
        next if @match_row[i] == -1

        @eligible_rows.each_with_index do |r2, j|
          next if j <= i || @match_row[j] == -1

          return true if try_swap(i, j, r, r2)
        end
      end

      false
    end

    def try_swap(idx, jdx, row, row2)
      col_i = @match_row[idx]
      col_j = @match_row[jdx]
      return false if @grid[row][col_j] == 'X' || @grid[row2][col_i] == 'X'
      return false if z_loss?(row, row2, col_i, col_j)
      return false unless @grid[row][col_j].to_f + @grid[row2][col_i].to_f <
        @grid[row][col_i].to_f + @grid[row2][col_j].to_f

      @match_row[idx] = col_j
      @match_row[jdx] = col_i
      @match_col[col_i] = jdx
      @match_col[col_j] = idx
      true
    end

    # Returns true if swapping would reduce the zero-malus match count.
    def z_loss?(row, row2, col_i, col_j)
      gained = (@grid[row][col_j].zero? ? 1 : 0) + (@grid[row2][col_i].zero? ? 1 : 0)
      lost   = (@grid[row][col_i].zero? ? 1 : 0) + (@grid[row2][col_j].zero? ? 1 : 0)
      (gained - lost).negative?
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
