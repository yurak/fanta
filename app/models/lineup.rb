class Lineup < ApplicationRecord
  has_many :match_players, dependent: :destroy
  has_many :players, through: :match_players

  accepts_nested_attributes_for :match_players
  accepts_nested_attributes_for :players

  belongs_to :team_module
  belongs_to :team
  belongs_to :tour

  FIRST_GOAL = 66
  INCRENMENT = 6

  def total_score
    match_players.main.map(&:total_score).compact.sum + defence_bonus
  end

  def defence_bonus
    # TODO: count defence bonus for lineup
    0
  end

  def goals
    return 0 if total_score < FIRST_GOAL

    ((total_score - FIRST_GOAL) / INCRENMENT + 1).floor
  end
end
