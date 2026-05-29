class Result < ApplicationRecord
  belongs_to :team
  belongs_to :league
  has_one :user_title, dependent: :destroy

  delegate :lineups, to: :team

  scope :ordered, lambda {
                    order(points: :desc)
                      .order(scored_goals: :desc)
                      .order(wins: :desc)
                      .order(total_score: :desc)
                      .order(Arel.sql('scored_goals - missed_goals desc'))
                      .order(id: :asc)
                  }
  scope :fanta_ordered, lambda {
                          order(total_score: :desc)
                            .order(points: :desc)
                            .order(best_lineup: :desc)
                        }
  scope :by_league, ->(league_id) { where(league_id: league_id) }
  scope :ordered_by_score, -> { order(total_score: :desc) }
  scope :by_team, ->(team_id) { where(team_id: team_id) }
  scope :finished, -> { joins(:league).where(leagues: { status: 2 }) }
  scope :title, -> { where(title: true) }
  scope :with_position, -> { where.not(position: nil) }
  scope :mantra, -> { joins(league: :tournament).where(leagues: { tournaments: { mode: 0 } }) }
  scope :fanta, -> { joins(league: :tournament).where(leagues: { tournaments: { mode: 1 } }) }
  scope :fanta_top, ->(position) { fanta.where('position > 0 AND position <= ?', position) if position }
  scope :fanta_top_ts, ->(position) { fanta.where('secondary_position > 0 AND secondary_position <= ?', position) if position }

  rails_admin do
    object_label_method { :to_s }
  end

  def to_s
    "#{team&.human_name} — #{league&.name}"
  end

  def lineup_pct
    finished_tours = league.tours.where(status: %i[locked closed postponed])
    total = finished_tours.count
    return 0 if total.zero?

    manual = team.lineups.where(tour: finished_tours, creation_type: %i[manual copied]).count
    (manual.to_f / total * 100).round
  end

  def crowned?
    title? && user_title.present?
  end

  def crownable?
    return title_crownable? if title?

    league_results = league.results.ordered
    return false unless league_results.first&.id == id

    return true if league.archived?

    remaining = league.tours.where.not(status: Tour.statuses[:closed]).count
    return true if remaining.zero?

    second = league_results.second
    return true if second.nil?

    points - second.points > remaining * 3
  end

  def title_crownable?
    user_title.nil?
  end

  def matches_played
    @matches_played ||= wins + draws + loses
  end

  def goals_difference
    @goals_difference ||= scored_goals - missed_goals
  end

  def live_position
    Result.where(league: league).ordered.find_index(self) + 1
  end

  def fanta_position
    Result.where(league: league).fanta_ordered.find_index(self) + 1
  end

  def promoted?
    return false unless league.mantra? && league.archived?

    (position || live_position) <= league.promotion
  end

  def relegated?
    return false unless league.mantra? && league.archived? && league.relegation.positive?

    (position || live_position) > league.results.count - league.relegation
  end

  def form
    @form ||= closed_lineups.limit(5).reverse.map { |l| [l.result, l.match_result, l.opponent&.code, l.tour_id] }
  end

  def history_arr
    @history_arr ||= JSON.parse(history)
  end

  def league_best_lineup
    return 0 if closed_lineups.empty?

    closed_lineups.max_by(&:total_score).total_score
  end

  def closed_lineups
    lineups.closed(league.id).includes(:tour)
  end
end
