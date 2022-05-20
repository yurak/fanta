class NationalMatch < ApplicationRecord
  belongs_to :tournament_round
  belongs_to :host_team, class_name: 'NationalTeam'
  belongs_to :guest_team, class_name: 'NationalTeam'

  default_scope { includes(%i[host_team guest_team]) }

  scope :by_team, ->(team_id) { where('host_team_id = ? OR guest_team_id = ?', team_id, team_id) }
  scope :by_t_round, ->(t_round_id) { where(tournament_round_id: t_round_id) }
end
