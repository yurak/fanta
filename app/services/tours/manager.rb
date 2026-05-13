module Tours
  class Manager < ApplicationService
    CLOSED_STATUS = 'closed'.freeze
    LOCKED_STATUS = 'locked'.freeze
    POSTPONED_STATUS = 'postponed'.freeze
    SET_LINEUP_STATUS = 'set_lineup'.freeze

    attr_reader :tour, :status

    def initialize(tour, status)
      @tour = tour
      @status = status
    end

    def call
      set_lineup

      lock

      postpone

      close
    end

    private

    def set_lineup
      return unless tour.inactive? && status == SET_LINEUP_STATUS

      tour.set_lineup! if RoundPlayers::Creator.call(tour.tournament_round.id)

      Notifications::Creator.call(notifiable: tour, kind: :tour_opened, priority: :normal)
    end

    def lock
      return unless tour.set_lineup? && status == LOCKED_STATUS

      tour.locked!
    end

    def postpone
      tour.postponed! if tour.locked? && status == POSTPONED_STATUS
    end

    def close
      return unless tour.locked_or_postponed? && status == CLOSED_STATUS && tour.tournament_round.finished?

      Tour.transaction do
        tour.closed!
        update_results
        Lineups::Updater.call(tour)
        RoundPlayers::Updater.call(tour.tournament_round)
        Notifications::Creator.call(notifiable: tour, kind: :tour_closed, priority: :normal)
      end
    end

    def update_results
      tour.fanta? ? Results::FantaUpdater.call(tour) : Results::Updater.call(tour)
    end
  end
end
