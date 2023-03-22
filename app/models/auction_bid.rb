class AuctionBid < ApplicationRecord
  belongs_to :auction_round
  belongs_to :team

  has_many :player_bids, dependent: :destroy

  delegate :auction, to: :auction_round

  enum status: { initial: 0, ongoing: 1, submitted: 2, completed: 3, processed: 4 }

  default_scope { includes(:player_bids) }

  accepts_nested_attributes_for :player_bids
end
