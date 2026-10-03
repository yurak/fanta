module ToursHelper
  LIVE_STANDING_RESULTS = { 1 => 'win', 0 => 'draw', -1 => 'loss' }.freeze

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

  def live_standing_results(tournament, season_id)
    TournamentMatch.live
                   .joins(:tournament_round)
                   .where(tournament_rounds: { tournament_id: tournament.id, season_id: season_id })
                   .each_with_object({}) do |match, acc|
      host = match.host_score.to_i
      guest = match.guest_score.to_i
      acc[match.host_club_id] = LIVE_STANDING_RESULTS[host <=> guest]
      acc[match.guest_club_id] = LIVE_STANDING_RESULTS[guest <=> host]
    end
  end

  def round_opponents(tournament_round)
    tournament_round.ordered_tournament_matches.each_with_object({}) do |match, acc|
      acc[match.host_club_id] = match.guest_club
      acc[match.guest_club_id] = match.host_club
    end
  end
end
