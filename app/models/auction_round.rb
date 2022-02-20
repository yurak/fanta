class AuctionRound < ApplicationRecord
  belongs_to :auction

  has_many :auction_bids, dependent: :destroy

  enum status: { active: 0, processing: 1, closed: 2 }

  def bid_exist?(team)
    auction_bids.find_by(team_id: team.id).present?
  end
end
