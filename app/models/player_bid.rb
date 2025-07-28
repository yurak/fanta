class PlayerBid < ApplicationRecord
  belongs_to :auction_bid
  belongs_to :player, optional: true

  delegate :team, to: :auction_bid

  enum status: { initial: 0, success: 1, failed: 2 }

  default_scope { includes(:player) }

  validate :auction_bid_allows_creation, on: :create

  private

  def auction_bid_allows_creation
    errors.add(:auction_bid, 'no longer allows creating player bids') if auction_bid&.player_bids_locked?
  end
end
