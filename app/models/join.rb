class Join < ApplicationRecord
  belongs_to :user
  belongs_to :tournament
  belongs_to :team

  enum status: { initial: 0, pending: 1, approved: 2, rejected: 3 }

  # TODO: assumes the join bid is always the first one (created during team registration).
  # Must be revisited when joins for existing teams are implemented.
  def auction_bid
    team.auction_bids.min_by(&:id)
  end

  validates :user_id, uniqueness: {
    scope: :tournament_id,
    message: :already_applied,
    conditions: -> { where.not(status: %i[initial rejected]) }
  }
end
