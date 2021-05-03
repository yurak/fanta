module Tours
  class Manager
    attr_reader :tour, :status

    def initialize(tour:, status:)
      @tour = tour
      @status = status
    end

    def call
      if any_tour_in_progress?
        tour.errors.add(:base, 'Please close active tour')
      else
        set_lineup
      end

      lock

      postpone

      close
    end

    private

    def set_lineup
      return unless status == 'set_lineup'

      tour.set_lineup! if RoundPlayers::Creator.call(tour.tournament_round.id)
    end

    def lock
      return unless tour.set_lineup? && status == 'locked'

      clone_missed_lineups

      tour.locked!
    end

    def postpone
      tour.postponed! if tour.locked? && status == 'postponed'
    end

    def close
      return unless tour.locked_or_postponed? && status == 'closed'

      tour.closed!
      Results::Updater.call(tour)
    end

    def clone_missed_lineups
      tour.teams.each do |team|
        next if tour.lineups.by_team(team.id).any?

        TeamLineups::Cloner.call(team: team, tour: tour)
      end
    end

    def any_tour_in_progress?
      league.tours.set_lineup.exists? || league.tours.locked.exists?
    end

    def league
      tour.league
    end
  end
end
