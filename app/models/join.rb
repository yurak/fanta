class Join < ApplicationRecord
  belongs_to :user
  belongs_to :tournament
  belongs_to :team
  belongs_to :auction_bid

  enum :status, { initial: 0, pending: 1, approved: 2, rejected: 3 }

  validates :user_id, uniqueness: {
    scope: :tournament_id,
    message: :already_applied,
    conditions: -> { where.not(status: %i[initial rejected]) }
  }
end
