class Tour < ApplicationRecord
  belongs_to :league
  belongs_to :tournament_round

  has_many :matches, dependent: :destroy
  has_many :lineups, dependent: :destroy

  delegate :teams, to: :league

  enum status: { inactive: 0, set_lineup: 1, locked: 2, closed: 3, postponed: 4 }

  scope :closed_postponed, -> { closed.or(postponed) }
  scope :active, -> { set_lineup.or(locked) }

  def locked_or_postponed?
    locked? || postponed?
  end

  def deadlined?
    locked_or_postponed? || closed?
  end

  def unlocked?
    inactive? || set_lineup?
  end

  def match_players
    MatchPlayer.by_tour(id)
  end
end
