class Result < ApplicationRecord
  belongs_to :team
  belongs_to :league

  delegate :lineups, to: :team

  default_scope { includes(%i[league team]) }

  scope :ordered, lambda {
                    order(points: :desc)
                      .order(scored_goals: :desc)
                      .order(wins: :desc)
                      .order(total_score: :desc)
                      .order(Arel.sql('scored_goals - missed_goals desc'))
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
    lineups.closed(league.id)
  end
end
