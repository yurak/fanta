class PlayerBid < ApplicationRecord
  belongs_to :auction_bid
  belongs_to :player

  enum status: { initial: 0, success: 1, failed: 2 }

  default_scope { includes(:player) }
end
