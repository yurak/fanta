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

    close
  end

  private

  def set_lineup
    tour.set_lineup! if status == 'set_lineup'
  end

  def lock
    tour.locked! if tour.set_lineup? && status == 'locked'
  end

  def close
    if tour.locked? && status == 'closed'
      tour.closed!
      ResultsManager.new(tour: tour).update
      MatchPlayerManager.new(tour: tour).create
    end
  end

  def any_tour_in_progress?
    Tour.set_lineup.exists? || Tour.locked.exists?
  end
end
