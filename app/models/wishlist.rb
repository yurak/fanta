class Wishlist < ApplicationRecord
  MAX_PLAYERS = 100

  belongs_to :user
  belongs_to :tournament
  belongs_to :season

  has_many :wishlist_players, dependent: :destroy
  has_many :players, through: :wishlist_players

  scope :by_season, ->(season_id) { where(season_id: season_id) }

  def self.fetch_or_create(user:, tournament:, season:)
    find_or_create_by(user: user, tournament: tournament, season: season)
  rescue ActiveRecord::RecordNotUnique
    find_by!(user: user, tournament: tournament, season: season)
  end

  def readable_by?(viewer)
    shared? || owned_by?(viewer)
  end

  def owned_by?(viewer)
    viewer.present? && user_id == viewer.id
  end

  def full?
    wishlist_players.count >= MAX_PLAYERS
  end
end
