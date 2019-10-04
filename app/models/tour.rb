class Tour < ApplicationRecord
  enum status: %i[inactive set_lineup locked closed postponed]

  has_many :matches, dependent: :destroy
  has_many :lineups, dependent: :destroy

  scope :closed_postponed, ->{ closed.or(postponed) }

  def locked_or_postponed?
    locked? || postponed?
  end

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
