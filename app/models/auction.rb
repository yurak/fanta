class Auction < ApplicationRecord
  belongs_to :league

  has_many :auction_rounds, dependent: :destroy
  has_many :transfers, dependent: :destroy

  # sales - outgoing transfers
  # blind_bids - only for leagues with blind auctions
  # live - only for leagues with live auctions
  enum status: { initial: 0, sales: 1, blind_bids: 2, live: 3, closed: 4 }

  scope :initial_sales, -> { initial.or(sales) }
end
