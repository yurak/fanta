class Join < ApplicationRecord
  belongs_to :user
  belongs_to :tournament
  belongs_to :team
  belongs_to :auction_bid
  belongs_to :season

  enum :status, { initial: 0, pending: 1, approved: 2, rejected: 3 }

  scope :current_season, -> { where(season_id: Season.last&.id) }

  before_validation :set_default_season, on: :create

  validates :user_id, uniqueness: {
    scope: %i[tournament_id season_id],
    message: :already_applied,
    conditions: -> { where.not(status: %i[initial rejected]) }
  }

  private

  def set_default_season
    self.season ||= Season.last
  end
end
