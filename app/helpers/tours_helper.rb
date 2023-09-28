module ToursHelper
  def time_to_deadline(time_hash)
    return '' if time_hash.blank?
    return 'more than 7 days' if time_hash[:weeks]&.positive? || time_hash[:months]&.positive?

    "#{time_left(time_hash)}left"
  end

  def time_left(time_hash)
    time_str = ''
    time_str += "#{time_hash[:days]}d " if time_hash[:days]&.positive?
    time_str += "#{time_hash[:hours]}h " if time_hash[:hours]&.positive?
    time_str += "#{time_hash[:minutes]}m " if time_hash[:minutes]&.positive?
    time_str
  end
end
