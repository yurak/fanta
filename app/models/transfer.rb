class Transfer < ApplicationRecord
  belongs_to :league
  belongs_to :player
  belongs_to :team

  enum status: { incoming: 0, outgoing: 1 }

  scope :by_league, ->(league_id) { where(league_id: league_id) }
  scope :by_player, ->(player_id) { where(player_id: player_id) }
end
