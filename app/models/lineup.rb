class Lineup < ApplicationRecord
  has_many :match_players
  has_many :players, through: :match_players

  accepts_nested_attributes_for :match_players
  accepts_nested_attributes_for :players


  belongs_to :team_module
  belongs_to :team
  belongs_to :tour

  def total_score

    match_players.map(&:total_score).compact.sum
  end

  def goals
    return 0 if total_score < 66

    ((total_score - 66)/6 + 1).floor
  end
end
