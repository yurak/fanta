module ToursHelper
  def time_to_deadline(time_hash)
    return '' if time_hash.blank?
    return 'more than 7 days left' if time_hash[:weeks]&.positive? || time_hash[:months]&.positive?

    "#{time_left(time_hash)}left"
  end

  def time_left(time_hash)
    time_str = ''
    time_str += "#{time_hash[:days]}d " if time_hash[:days]&.positive?
    time_str += "#{time_hash[:hours]}h " if time_hash[:hours]&.positive?
    time_str += "#{time_hash[:minutes]}m " if time_hash[:minutes]&.positive?
    time_str
  end

  # {club_id => the club it faces} for one round, so the standings table can show each club's
  # opponent without a query per row.
  def round_opponents(tournament_round)
    tournament_round.ordered_tournament_matches.each_with_object({}) do |match, acc|
      acc[match.host_club_id] = match.guest_club
      acc[match.guest_club_id] = match.host_club
    end
  end
end
