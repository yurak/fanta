class AuctionBid < ApplicationRecord
  belongs_to :auction_round
  belongs_to :team

  has_many :player_bids, dependent: :destroy

  default_scope { includes(:player_bids) }

  accepts_nested_attributes_for :player_bids
end
