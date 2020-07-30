class TourManager
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

    RoundPlayerManager.call(tournament_round: tour.tournament_round)

    tour.set_lineup!
  end

  def lock
    return unless tour.set_lineup? && status == 'locked'

    tour.locked!
  end

  def postpone
    tour.postponed! if tour.locked? && status == 'postponed'
  end

  def close
    return unless tour.locked_or_postponed? && status == 'closed'

    tour.closed!
    Results::Updater.call(tour: tour)
  end

  def any_tour_in_progress?
    league.tours.set_lineup.exists? || league.tours.locked.exists?
  end

  def league
    tour.league
  end
end
