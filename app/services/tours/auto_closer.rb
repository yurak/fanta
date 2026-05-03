# frozen_string_literal: true

module Tours
  class AutoCloser < ApplicationService
    def initialize(tournament_round)
      @tournament_round = tournament_round
    end

    def call
      return false unless enough_hours_passed?

      tournament_round.tours.locked_postponed.each do |tour|
        Tours::Manager.call(tour, Tours::Manager::CLOSED_STATUS)
      end
      tournament_round.update!(moderated_at: nil)
      true
    end

    private

    attr_reader :tournament_round

    def enough_hours_passed?
      hours_since_moderated >= TournamentRound::MODERATED_HOURS
    end

    def hours_since_moderated
      ((Time.zone.now - tournament_round.moderated_at) / 3_600).to_i
    end
  end
end
