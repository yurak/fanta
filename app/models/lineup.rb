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
  scope :closed, ->{ where(tour_id: Tour.closed.ids) }

  FIRST_GOAL = 66
  INCREMENT = 6
  MIN_AVG_SCORE = 6
  MAX_AVG_SCORE = 7
  DEF_BONUS_STEP = 0.25

  def total_score
    match_players.main.map(&:total_score).compact.sum + defence_bonus
  end

  def defence_bonus
    return 0 if def_average_score < MIN_AVG_SCORE
    return 5 if def_average_score >= MAX_AVG_SCORE

    ((def_average_score - MIN_AVG_SCORE) / DEF_BONUS_STEP + 1).floor
  end

  def goals
    return 0 if total_score < FIRST_GOAL

    ((total_score - FIRST_GOAL) / INCREMENT + 1).floor
  end

  def match
    @match ||= Match.by_team_and_tour(team.id, tour.id).first
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

  def mp_with_score
    @mp_with_score ||= match_players.main_with_score.size
  end

  private

  def def_count
    @def_count ||= match_players.defenders.count
  end

  def def_scores_sum
    match_players.defenders.map(&:score).compact.sum
  end

  def def_average_score
    return 0 if match_players.defenders.empty?
    def_scores_sum / def_count
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
end
