# frozen_string_literal: true

module Tours
  class AutoInjector < ApplicationService
    INJECT_AT_HOURS = [6, 12, 17].freeze

    def initialize(tournament_round)
      @tournament_round = tournament_round
    end

    def call
      return false unless inject_hour?

      injector.call(tournament_round)
      update_tours
      true
    end

    private

    attr_reader :tournament_round

    def inject_hour?
      INJECT_AT_HOURS.include?(hours_since_moderated)
    end

    def hours_since_moderated
      ((Time.zone.now - tournament_round.moderated_at) / 3_600).to_i
    end

    def injector
      "Scores::Injectors::#{tournament_round.tournament.source.capitalize}".constantize
    end

    def update_tours
      tournament_round.tours.each do |tour|
        Scores::PositionMalus::Updater.call(tour)
        Lineups::Updater.call(tour)
      end
    end
  end
end
