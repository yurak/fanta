module Lineups
  class Updater < ApplicationService
    attr_reader :tour

    def initialize(tour)
      @tour = tour
    end

    def call
      return false if tour&.lineups.blank?

      tour.lineups.each do |lineup|
        lineup.update(final_score: lineup.current_score)
        lineup.reload.update(final_goals: lineup.live_goals)
      end

      update_points if tour.fanta?
    end

    private

    def update_points
      i = 0
      tour.ordered_lineups.group_by(&:total_score).each_value do |lineups|
        points = i < Results::FantaUpdater::POINTS_MAP.length ? Results::FantaUpdater::POINTS_MAP[i] : 0

        lineups.each do |lineup|
          lineup.update(points: points, position: i + 1)
        end
        i += lineups.count
      end
    end
  end
end
