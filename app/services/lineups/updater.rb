module Lineups
  class Updater < ApplicationService
    attr_reader :tour

    def initialize(tour)
      @tour = tour
    end

    def call
      return false if tour&.lineups.blank?

      tour.lineups.each do |lineup|
        lineup.update(final_score: lineup.current_score, final_goals: lineup.goals)
      end
    end
  end
end
