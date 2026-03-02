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

      @eligible_rows.each_with_index do |_r, i|
        augment(i, Array.new(@n, false))
      end

      improve
      report
    end

    private

    def prepare
      @eligible_rows = (0...@m).select { |r| @grid[r].any? { |v| v != 'X' } }
      @edges = @eligible_rows.map do |r|
        (0...@n).reject { |c| @grid[r][c] == 'X' }
                .sort_by { |c| @grid[r][c] }
      end
      @match_col = Array.new(@n, -1)
      @match_row = Array.new(@eligible_rows.size, -1)
    end

    def augment(idx, visited)
      @edges[idx].each do |c|
        next if visited[c]

        visited[c] = true

        next unless @match_col[c] == -1 || augment(@match_col[c], visited)

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

          ci = @match_row[i]
          cj = @match_row[j]
          next if @grid[r][cj] == 'X' || @grid[r2][ci] == 'X'
          next unless @grid[r][cj].to_f + @grid[r2][ci].to_f < @grid[r][ci].to_f + @grid[r2][cj].to_f

          @match_row[i] = cj
          @match_row[j] = ci
          @match_col[ci] = j
          @match_col[cj] = i
          return true
        end
      end

      false
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
