class Result < ApplicationRecord
  belongs_to :team
  belongs_to :league

  delegate :lineups, to: :team

  scope :ordered, -> { order(points: :desc).order(Arel.sql('scored_goals - missed_goals desc')).order(scored_goals: :desc) }
  scope :ordered_by_score, -> { order(total_score: :desc) }

  def matches_played
    @matches_played ||= wins + draws + loses
  end

  def goals_difference
    @goals_difference ||= scored_goals - missed_goals
  end

  def position
    Result.where(league: league).ordered.find_index(self) + 1
  end

  def form
    @form ||= closed_lineups.limit(5).map { |l| [l.result, l.match_result, l.opponent.code, l.tour_id] }
  end

  def league_best_lineup
    return 0 if closed_lineups.empty?

    closed_lineups.max_by(&:total_score).total_score
  end

  private

  def closed_lineups
    lineups.closed(league.id)
  end
end
