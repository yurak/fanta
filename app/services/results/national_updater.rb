module Results
  class NationalUpdater < ApplicationService
    F1_POINTS = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1].freeze

    attr_reader :tour

    def initialize(tour)
      @tour = tour
    end

    def call
      return false unless tour&.closed? && lineups.any?

      update_total_scores
      update_f1_points
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

    def update_f1_points
      i = 0
      lineups.take(10).group_by(&:total_score).each do |_, lineups|
        lineups.each do |lineup|
          result = lineup.team.results.last

          result.update(points: result.points + F1_POINTS[i])
        end
        i += lineups.count
      end
    end

    def lineups
      @lineups ||= tour.ordered_lineups
    end
  end
end
