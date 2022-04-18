module Lineups
  class Updater < ApplicationService
    attr_reader :tour

    def initialize(tour)
      @tour = tour
    end

    def call
      return false unless tour&.lineups.present? && tour.closed?

      tour.lineups.each do |lineup|
        lineup.update(final_score: lineup.total_score)
      end
    end
  end
end
