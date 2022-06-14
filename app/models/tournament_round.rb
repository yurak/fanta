class TournamentRound < ApplicationRecord
  belongs_to :tournament
  belongs_to :season

  has_many :national_matches, dependent: :destroy
  has_many :round_players, dependent: :destroy
  has_many :tournament_matches, dependent: :destroy
  has_many :tours, dependent: :destroy

  scope :by_tournament, ->(tournament_id) { where(tournament: tournament_id) }
  scope :by_season, ->(season_id) { where(season: season_id) }

  def eurocup_players
    return [] unless tournament.eurocup?

    round_players.by_club(clubs_ids)
  end

  def clubs_ids
    tournament_matches.pluck(:host_club_id, :guest_club_id).flatten
  end

  def finished?
    tournament_matches.any? && tournament_matches.where(host_score: nil).empty?
  end

  def time_to_deadline
    return '' unless deadline

    TimeDifference.between(Time.zone.parse(deadline&.strftime('%a, %b %e at %H:%M')), Time.zone.now).in_general
  end
end
