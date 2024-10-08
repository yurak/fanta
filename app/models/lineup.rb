class Lineup < ApplicationRecord
  belongs_to :team_module
  belongs_to :team
  belongs_to :tour

  has_many :match_players, dependent: :destroy
  has_many :round_players, through: :match_players

  accepts_nested_attributes_for :match_players
  accepts_nested_attributes_for :round_players

  delegate :slots, to: :team_module
  delegate :tournament_round, to: :tour
  delegate :league, to: :team

  default_scope { includes(%i[team tour]) }

  scope :closed, ->(league_id) { where(tour_id: League.find(league_id).tours.closed.ids) }
  scope :by_league, ->(league_id) { where(tour_id: League.find(league_id).tours.ids) }
  scope :by_team, ->(team_id) { where(team_id: team_id) }
  scope :top_position, ->(position) { where('position > 0 AND position <= ?', position) if position }

  MIN_AVG_DEF_SCORE = 6
  MAX_AVG_DEF_SCORE = 7
  DEF_BONUS_STEP = 0.25
  MAX_PLAYED_PLAYERS = 11
  MAX_FANTA_PLAYERS = 16
  MAX_PLAYERS = 20

  def total_score
    return final_score unless final_score.zero?
    return final_score if tour.fanta?

    current_score
  end

  def current_score
    @current_score ||= match_players.main.map(&:total_score).compact.sum + defence_bonus
  end

  def defence_bonus
    return 0 if def_average_score < min_avg_def_score
    return 5 if def_average_score >= max_avg_def_score

    (((def_average_score - min_avg_def_score) / DEF_BONUS_STEP) + 1).floor
  end

  def goals
    return final_goals unless final_goals.nil?

    live_goals
  end

  def live_goals
    return 0 if total_score < first_goal

    (((total_score - first_goal) / goal_increment) + 1).floor
  end

  def match
    @match ||= Match.by_team_and_tour(team.id, tour.id).first
  end

  def result
    return '' unless match

    if win?
      'W'
    elsif lose?
      'L'
    elsif draw?
      'D'
    end
  end

  def completed?
    mp_with_score == MAX_PLAYED_PLAYERS
  end

  def mp_with_score
    @mp_with_score ||= match_players.main_with_score.size
  end

  def opponent
    match.host == team ? match.guest : match.host
  end

  def match_result
    match.host == team ? "#{match.host_goals}-#{match.guest_goals}" : "#{match.guest_goals}-#{match.host_goals}"
  end

  def players_count
    if tour.fanta?
      MAX_FANTA_PLAYERS
    else
      tour.expanded? ? team&.players&.count : MAX_PLAYERS
    end
  end

  def subs_missed?
    match_players.main.without_score.any?(&:subs_option_exist?)
  end

  def substitutes_preview
    return [] unless substitutes

    JSON.parse(substitutes)
  end

  def best_player
    match_players.joins(:round_player).main.order('round_players.final_score': :desc).first&.player
  end

  private

  def first_goal
    return 72 unless team.league

    team.tournament.lineup_first_goal
  end

  def goal_increment
    return 7 unless team.league

    team.tournament.lineup_increment
  end

  def min_avg_def_score
    league&.min_avg_def_score || MIN_AVG_DEF_SCORE
  end

  def max_avg_def_score
    league&.max_avg_def_score || MAX_AVG_DEF_SCORE
  end

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
    (match.host_win? && match.host == team) || (match.guest_win? && match.guest == team)
  end

  def lose?
    (match.guest_win? && match.host == team) || (match.host_win? && match.guest == team)
  end
end
