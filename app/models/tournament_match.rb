class TournamentMatch < ApplicationRecord
  belongs_to :tournament_round
  belongs_to :host_club, class_name: 'Club'
  belongs_to :guest_club, class_name: 'Club'

  default_scope { includes(%i[host_club guest_club tournament_round]) }

  scope :by_club, ->(club_id) { where('host_club_id = ? OR guest_club_id = ?', club_id, club_id) }
  scope :by_club_and_t_round, ->(club_id, t_round_id) { by_club(club_id).where(tournament_round_id: t_round_id) }
end
