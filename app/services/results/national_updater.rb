module Results
  class NationalUpdater < ApplicationService
    POINTS_MAP = [60, 54, 48, 43, 40, 38, 36, 34, 32, 31,
                  30, 29, 28, 27, 26, 25, 24, 23, 22, 21,
                  20, 19, 18, 17, 16, 15, 14, 13, 12, 11,
                  10,  9,  8,  7,  6,  5,  4,  3,  2,  1].freeze

    attr_reader :tour

    def initialize(tour)
      @tour = tour
    end

    def call
      return false unless tour&.closed? && lineups.any?

      update_total_scores
      update_points
    end

    private

    def update_total_scores
      lineups.each do |lineup|
        result = lineup.team.results.last

        result.update(best_lineup: lineup.total_score.round(2)) if lineup.total_score > result.best_lineup

        result.update(
          total_score: result.total_score + lineup.total_score.round(2),
          draws: result.draws + 1
        )
      end
    end

    def update_points
      i = 0
      lineups.take(POINTS_MAP.length).group_by(&:total_score).each_value do |lineups|
        lineups.each do |lineup|
          result = lineup.team.results.last

          result.update(points: result.points + POINTS_MAP[i])
        end
        i += lineups.count
      end
    end

    def lineups
      @lineups ||= tour.ordered_lineups
    end
  end
end
