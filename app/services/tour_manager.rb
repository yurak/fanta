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
    tour.set_lineup! if status == 'set_lineup'
  end

  def lock
    return unless tour.set_lineup? && status == 'locked'

    tour.locked!
    MatchPlayerManager.new(tour: tour).create
  end

  def postpone
    tour.postponed! if tour.locked? && status == 'postponed'
  end

  def close
    return unless tour.locked_or_postponed? && status == 'closed'

    tour.closed!
    ResultsManager.new(tour: tour).update
  end

  def any_tour_in_progress?
    # TODO: specify League tours
    Tour.set_lineup.exists? || Tour.locked.exists?
  end
end
