class Lineup < ApplicationRecord
  has_many :match_players, dependent: :destroy
  has_many :players, through: :match_players

  accepts_nested_attributes_for :match_players
  accepts_nested_attributes_for :players

  belongs_to :team_module
  belongs_to :team
  belongs_to :tour

  delegate :slots, to: :team_module

  scope :not_active, ->{ where.not(tour_id: Tour.active_tour&.id) }

  FIRST_GOAL = 66
  INCREMENT = 6

  def total_score
    @total_score ||= match_players.main.map(&:total_score).compact.sum + defence_bonus
  end

  def defence_bonus
    # TODO: count defence bonus for lineup
    0
  end

  def goals
    return 0 if total_score < FIRST_GOAL

    ((total_score - FIRST_GOAL) / INCREMENT + 1).floor
  end

  def match
    @match ||= Match.by_team_and_tour(team.id, tour.id).first
  end

  def draw?
    match.draw?
  end

  def win?
    match.host_win? && match.host == team || match.guest_win? && match.guest == team
  end

  def lose?
    match.guest_win? && match.host == team || match.host_win? && match.guest == team
  end

  def result
    if win?
      'W'
    elsif lose?
      'L'
    elsif draw?
      'D'
    end
  end
end
