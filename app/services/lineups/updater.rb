module Lineups
  class Updater < ApplicationService
    attr_reader :tour

    def initialize(tour)
      @tour = tour
    end

    def call
      return false if tour&.lineups.blank?

      tour.lineups.each do |lineup|
        lineup.final_score = lineup.current_score
        lineup.update(final_score: lineup.final_score, final_goals: lineup.live_goals)
      end

      update_points if tour.fanta?
    end

    private

    def update_points
      tour.ordered_lineups.each_with_index do |lineup, i|
        points = i < Results::FantaUpdater::POINTS_MAP.length ? Results::FantaUpdater::POINTS_MAP[i] : 0
        lineup.update(points: points, position: i + 1)
      end
    end
  end
end
