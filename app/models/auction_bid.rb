class AuctionBid < ApplicationRecord
  belongs_to :auction_round, optional: true
  belongs_to :team

  has_many :player_bids, -> { order(:id) }, dependent: :destroy, inverse_of: :auction_bid

  delegate :auction, to: :auction_round, allow_nil: true

  enum :status, { initial: 0, ongoing: 1, submitted: 2, completed: 3, processed: 4 }

  validates :team_id, uniqueness: { scope: :auction_round_id }, if: -> { auction_round_id.present? }

  scope :initial_ongoing, -> { initial.or(ongoing) }

  accepts_nested_attributes_for :player_bids

  def join
    return @join if defined?(@join)

    @join = Join.current_season.find_by(auction_bid_id: id)
  end

  def editable?
    initial? || ongoing? || submitted?
  end

  def lock_player_bids!
    update!(player_bids_locked: true)
  end
end
