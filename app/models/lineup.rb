class Lineup < ApplicationRecord
  belongs_to :team_module
  belongs_to :team
  belongs_to :tour

  has_many :match_players, dependent: :destroy, inverse_of: :lineup

  accepts_nested_attributes_for :match_players

  delegate :slots, to: :team_module
  delegate :tournament_round, to: :tour
  delegate :league, to: :team

  enum creation_type: { manual: 0, copied: 1, auto_cloned: 2 }

  before_create { self.last_edited_at ||= Time.current }

  scope :closed, ->(league_id) { where(tour_id: League.find(league_id).tours.closed.select(:id)) }
  scope :finished, -> { joins(:tour).where(tours: { status: :closed }) }
  scope :mantra, -> { joins(tour: { tournament_round: :tournament }).where(tournaments: { mode: :mantra }) }
  scope :fanta, -> { joins(tour: { tournament_round: :tournament }).where(tournaments: { mode: :fanta }) }
  scope :by_league, ->(league_id) { where(tour_id: League.find(league_id).tours.select(:id)) }
  scope :by_team, ->(team_id) { where(team_id: team_id) }
  scope :top_position, ->(position) { where('position > 0 AND position <= ?', position) if position }

  MIN_AVG_DEF_SCORE = 6
  MAX_AVG_DEF_SCORE = 7
  DEF_BONUS_STEP = 0.25
  MAX_PLAYED_PLAYERS = 11
  MAX_FANTA_PLAYERS = 16
  MAX_PLAYERS = 20

  def total_score
    return final_score if final_score.nonzero? || tour.fanta?

    current_score
  end

  def current_score
    @current_score ||= match_players.main.sum(&:total_score) + defence_bonus
  end

  def defence_bonus
    avg = def_average_score

    return 0 if avg < min_avg_def_score
    return 5 if avg >= max_avg_def_score

    (((avg - min_avg_def_score) / DEF_BONUS_STEP) + 1).floor
  end

  def def_average_score
    @def_average_score ||= begin
      scores = match_players.defenders.joins(:round_player)
                            .pluck('match_players.id', 'round_players.score')
                            .uniq { |id, _| id }.map { |_, score| score }
      scores.empty? ? 0 : scores.sum / scores.size.to_f
    end
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
    return unless match

    match.host == team ? match.guest : match.host
  end

  def match_result
    return '' unless match

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
    match_players.main.without_score.includes(round_player: :tournament_round).any?(&:subs_option_exist?)
  end

  def substitutes_preview
    return [] unless substitutes

    JSON.parse(substitutes)
  end

  def best_player
    match_players.joins(:round_player).main.reorder('round_players.final_score': :desc).first&.player
  end

  def best_main_score
    match_players.main.map(&:total_score).max || 0
  end

  def best_bench_score
    match_players.subs_bench.map(&:total_score).max || 0
  end

  def bench_total_score
    match_players.subs_bench.sum(&:total_score)
  end

  def average_bench
    subs = match_players.with_score.subs_bench
    return 0 if subs.empty?

    (subs.sum(&:total_score) / subs.count).round(2)
  end

  def fanta_copyable?
    tour.fanta? && fanta_copy_targets.any?
  end

  def fanta_copy_targets
    return [] unless tour.fanta?

    fanta_sibling_teams.filter_map do |sibling_team|
      target_tour = sibling_team.league.tours.set_lineup.find_by(tournament_round: tour.tournament_round)
      next unless target_tour && !sibling_team.lineups.exists?(tour: target_tour)

      { team: sibling_team, tour: target_tour }
    end
  end

  private

  def fanta_sibling_teams
    team.user.teams
        .joins(:league)
        .where(leagues: { tournament_id: tour.tournament_round.tournament_id })
        .where.not(id: team.id)
  end

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
