class AuctionBid < ApplicationRecord
  belongs_to :auction_round, optional: true
  belongs_to :team

  has_many :player_bids, dependent: :destroy

  delegate :auction, to: :auction_round, allow_nil: true

  enum status: { initial: 0, ongoing: 1, submitted: 2, completed: 3, processed: 4 }

  scope :initial_ongoing, -> { initial.or(ongoing) }

  scope :initial_ongoing, -> { initial.or(ongoing) }

  accepts_nested_attributes_for :player_bids

  def editable?
    initial? || ongoing? || submitted?
  end

  def lock_player_bids!
    update!(player_bids_locked: true)
  end
end
