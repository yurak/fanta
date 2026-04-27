module Substitutes
  class TieredMatcher < ApplicationService # rubocop:disable Metrics/ClassLength
    def initialize(grid)
      @grid = grid
      @m = grid.size
      @n = @m.positive? ? grid[0].size : 0
    end

    def call
      return [[], 0.0] if @m.zero? || @n.zero?

      prepare
      return [[], 0.0] if @eligible_rows.empty?

      phase1
      phase2
      improve
      squeeze
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

    # Phase 1: maximise zero-malus matches first (highest priority)
    def phase1
      @eligible_rows.each_with_index do |_r, i|
        augment_zero(i, Array.new(@n, false))
      end
    end

    # Phase 2: maximise total matches without reducing zero-malus count.
    # 2a and 2b must stay separate — 2a must complete before 2b starts.
    def phase2
      phase2a
      phase2b
    end

    # 2a: direct match to a free column — never touches zero-malus slots
    def phase2a
      @eligible_rows.each_with_index do |_r, i|
        next if @match_row[i] != -1

        @all_edges[i].each do |c|
          next unless @match_col[c] == -1

          @match_col[c] = i
          @match_row[i] = c
          break
        end
      end
    end

    # 2b: augmenting path for rows still unmatched; roll back if zero-malus count drops
    def phase2b
      @eligible_rows.each_with_index do |_r, i|
        next if @match_row[i] != -1

        zero_before     = count_zero_assignments
        saved_match_col = @match_col.dup
        saved_match_row = @match_row.dup

        augment_full(i, Array.new(@n, false), zero_only: false)

        if count_zero_assignments < zero_before
          @match_col = saved_match_col
          @match_row = saved_match_row
        end
      end
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

    # After malus is optimised, reassign each tier's rows to the earliest possible bench
    # positions (lowest column indices) without reducing the number of matched rows.
    def squeeze
      tiers = (0...@eligible_rows.size).filter_map do |i|
        c = @match_row[i]
        next if c == -1

        @grid[@eligible_rows[i]][c]
      end.uniq.sort

      tiers.each { |v| squeeze_tier(v) }
    end

    def tier_idxs(malus_val)
      (0...@eligible_rows.size).select do |i|
        c = @match_row[i]
        c != -1 && @grid[@eligible_rows[i]][c] == malus_val
      end
    end

    # Greedy-reassign rows matched at +malus_val+ to their lowest available column,
    # then minimize the sum of assigned column indices within the tier.
    # Rolls back if any row in the tier loses its match (cross-tier column conflicts).
    def squeeze_tier(malus_val)
      idxs = tier_idxs(malus_val)
      return if idxs.empty?

      tier_edges = build_tier_edges(idxs, malus_val)
      saved_col  = @match_col.dup
      saved_row  = @match_row.dup

      unmatch_tier(idxs)
      greedy_assign_tier(idxs, tier_edges).each do |i|
        augment_tier(i, tier_edges, Array.new(@n, false))
      end
      minimize_tier_columns(idxs, tier_edges)

      return unless idxs.any? { |i| @match_row[i] == -1 }

      @match_col = saved_col
      @match_row = saved_row
    end

    # Iteratively reduce the sum of assigned column indices within a tier.
    def minimize_tier_columns(tier_rows, tier_edges)
      improved = true
      while improved
        improved = false
        tier_rows.each { |i| improved = true if shift_row_left(i, tier_rows, tier_edges) }
      end
    end

    # Try to move row i to a lower column. Returns true if a move was made.
    # 1. target_col is free — move directly.
    # 2. target_col is occupied by a tier row — find a free escape col for it strictly
    #    between target_col and current_col so the net column-index sum decreases.
    def shift_row_left(row_idx, tier_rows, tier_edges)
      current_col = @match_row[row_idx]
      return false if current_col == -1

      tier_edges[row_idx].each do |target_col|
        break if target_col >= current_col

        return true if try_move_to_col(row_idx, current_col, target_col, tier_rows, tier_edges)
      end
      false
    end

    def try_move_to_col(row_idx, current_col, target_col, tier_rows, tier_edges)
      occupant = @match_col[target_col]
      if occupant == -1
        reassign(row_idx, current_col, target_col)
      elsif tier_rows.include?(occupant)
        escape = tier_edges[occupant].find { |c| c > target_col && c < current_col && @match_col[c] == -1 }
        return false unless escape

        reassign(occupant, target_col, escape)
        reassign(row_idx, current_col, target_col)
      else
        return false
      end
      true
    end

    def reassign(row_idx, old_col, new_col)
      @match_col[old_col]    = -1
      @match_col[new_col]    = row_idx
      @match_row[row_idx]    = new_col
    end

    def build_tier_edges(tier_idxs, malus_val)
      tier_idxs.to_h do |i|
        r = @eligible_rows[i]
        [i, (0...@n).select { |c| @grid[r][c] == malus_val }]
      end
    end

    def unmatch_tier(tier_idxs)
      tier_idxs.each do |i|
        @match_col[@match_row[i]] = -1
        @match_row[i] = -1
      end
    end

    # Returns indices of rows that could not be assigned greedily.
    def greedy_assign_tier(tier_idxs, tier_edges)
      tier_idxs.reject do |i|
        tier_edges[i].any? do |c|
          next false if @match_col[c] != -1

          @match_col[c] = i
          @match_row[i] = c
          true
        end
      end
    end

    # Augmenting path within a single malus tier (only displaces rows in tier_edges).
    def augment_tier(idx, tier_edges, visited)
      tier_edges[idx].each do |c|
        next if visited[c]

        visited[c] = true
        j = @match_col[c]

        next unless j == -1 || (tier_edges.key?(j) && augment_tier(j, tier_edges, visited))

        @match_col[c] = idx
        @match_row[idx] = c
        return true
      end

      false
    end

    def improve_pass
      @eligible_rows.each_with_index do |r, i|
        next if @match_row[i] == -1

        @eligible_rows.each_with_index do |r2, j|
          next if j <= i || @match_row[j] == -1

          return true if try_swap(i, j, r, r2)
          return true if try_escape_swap(i, j, r, r2)
          return true if try_escape_swap(j, i, r2, r)
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

    # If row idx holds a zero-malus column that row jdx would benefit from,
    # try to escape row idx to another free zero-malus column.
    # Preserves zero-malus count: idx stays at zero, jdx improves.
    def try_escape_swap(idx, jdx, row, row2)
      col_i = @match_row[idx]
      col_j = @match_row[jdx]

      return false unless (@grid[row][col_i]).zero?
      return false if @grid[row2][col_i] == 'X'
      return false unless @grid[row2][col_i].to_f < @grid[row2][col_j].to_f

      max_escape_val = @grid[row2][col_j].to_f - @grid[row2][col_i].to_f
      escape_col = find_escape_col(idx, row, col_i, col_j, max_escape_val)
      return false unless escape_col

      # Non-zero escape is only Z-neutral if jdx gains zero at the freed slot
      return false if !(@grid[row][escape_col]).zero? && !(@grid[row2][col_i]).zero?

      @match_col[col_i] = jdx
      @match_row[jdx] = col_i
      @match_col[col_j] = -1
      @match_col[escape_col] = idx
      @match_row[idx] = escape_col
      true
    end

    # Returns a free column for idx to escape to, freeing col_i for jdx.
    # Prefers a zero-malus column; falls back to a non-zero column whose malus
    # does not exceed max_escape_val (jdx savings minus idx cost must be >= 0)
    # and uses an earlier bench position (c < col_j) to guarantee convergence.
    def find_escape_col(idx, row, col_i, col_j, max_escape_val)
      @zero_edges[idx].find { |c| c != col_i && @match_col[c] == -1 } ||
        @all_edges[idx].find do |c|
          c != col_i && @match_col[c] == -1 &&
            !(@grid[row][c]).zero? && @grid[row][c].to_f <= max_escape_val && c < col_j
        end
    end

    # Returns true if swapping would reduce the zero-malus match count.
    def z_loss?(row, row2, col_i, col_j)
      gained = (@grid[row][col_j].zero? ? 1 : 0) + (@grid[row2][col_i].zero? ? 1 : 0)
      lost   = (@grid[row][col_i].zero? ? 1 : 0) + (@grid[row2][col_j].zero? ? 1 : 0)
      (gained - lost).negative?
    end

    def count_zero_assignments
      @eligible_rows.each_with_index.count { |r, i| (c = @match_row[i]) != -1 && (@grid[r][c]).zero? }
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
