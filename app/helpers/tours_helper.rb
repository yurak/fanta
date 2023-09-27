module ToursHelper
  def time_to_deadline(time_hash)
    return '' if time_hash.blank?

    time_str = ''
    time_str += "#{(time_hash[:weeks] * 7) + time_hash[:days]}d " if time_hash[:days]&.positive? || time_hash[:weeks]&.positive?
    time_str += "#{time_hash[:hours]}h " if time_hash[:hours]&.positive?
    time_str += "#{time_hash[:minutes]}m " if time_hash[:minutes]&.positive?
    "#{time_str}left"
  end
end
