class Auction < ApplicationRecord
  belongs_to :league

  has_many :transfers, dependent: :destroy

  # TODO: update status names
  enum status: { initial: 0, open_bids: 1, active: 2, closed: 3 }
end
