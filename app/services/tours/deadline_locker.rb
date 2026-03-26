# frozen_string_literal: true

module Tours
  class DeadlineLocker < ApplicationService
    def initialize(tour)
      @tour = tour
    end

    def call
      return false unless deadline
      return false unless deadline < Time.current

      Tours::Manager.call(tour, Tours::Manager::LOCKED_STATUS)
      true
    end

    private

    attr_reader :tour

    def deadline
      tour.tournament_round.deadline
    end
  end
end
