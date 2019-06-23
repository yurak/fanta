class TourManager
  attr_reader :tour, :status

  def initialize(tour:, status:)
    @tour = tour
    @status = status
  end

  def call
    if any_tour_in_progress?
      tour.errors.add(:base, 'Please close tour in progress')
    else
      set_lineup
    end

    close
  end

  private

  def set_lineup
    tour.set_lineup! if status == 'set_lineup'
  end

  def close
    tour.closed! if tour.set_lineup? && status == 'closed'
  end

  def any_tour_in_progress?
    Tour.set_lineup.exists?
  end
end
