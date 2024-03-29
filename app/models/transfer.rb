class Transfer < ApplicationRecord
  belongs_to :auction, optional: true
  belongs_to :league
  belongs_to :player
  belongs_to :team

  enum status: { incoming: 0, outgoing: 1, left: 2 }

  default_scope { includes(%i[player team]) }

  scope :by_league, ->(league_id) { where(league_id: league_id) }
  scope :by_player, ->(player_id) { where(player_id: player_id) }
  scope :by_auction, ->(auction_id) { where(auction_id: auction_id) }
end
