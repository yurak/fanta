module Tours
  class Manager < ApplicationService
    SET_LINEUP_STATUS = 'set_lineup'.freeze
    LOCKED_STATUS = 'locked'.freeze
    POSTPONED_STATUS = 'postponed'.freeze
    CLOSED_STATUS = 'closed'.freeze

    attr_reader :tour, :status

    def initialize(tour:, status:)
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
      return if status != SET_LINEUP_STATUS

      tour.set_lineup! if RoundPlayers::Creator.call(tour.tournament_round.id)
    end

    def lock
      return unless tour.set_lineup? && status == LOCKED_STATUS

      clone_missed_lineups

      tour.locked!
    end

    def postpone
      tour.postponed! if tour.locked? && status == POSTPONED_STATUS
    end

    def close
      return unless tour.locked_or_postponed? && status == CLOSED_STATUS

      tour.closed!
      Results::Updater.call(tour)
    end

    def clone_missed_lineups
      tour.teams.each do |team|
        next if tour.lineups.by_team(team.id).any?

        TeamLineups::Cloner.call(team: team, tour: tour)
      end
    end

    def league
      tour.league
    end
  end
end
