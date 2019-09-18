class Tour < ApplicationRecord
  enum status: %i[inactive set_lineup locked closed]

  has_many :matches, dependent: :destroy
  has_many :lineups, dependent: :destroy

  def next_number
    number + 1
  end

  def self.active_tour
    Tour.set_lineup.first || Tour.locked.first
  end

  def match_players
    MatchPlayer.by_tour(id)
  end
end
