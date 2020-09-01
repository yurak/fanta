class Result < ApplicationRecord
  belongs_to :team
  belongs_to :league

  delegate :lineups, to: :team

  scope :ordered, -> { order(points: :desc).order(Arel.sql('scored_goals - missed_goals desc')).order(scored_goals: :desc) }

  def matches_played
    @matches_played ||= wins + draws + loses
  end

  def goals_difference
    @goals_difference ||= scored_goals - missed_goals
  end

  # TODO: show correct lineups, related league and team (as team could have lineups in new season and league)
  # def form
  #   @form ||= closed_lineups.limit(5).map { |l| [l.result, l.match_result, l.opponent.code_name, l.tour_id] }
  # end
  #
  # def closed_lineups
  #   lineups.closed(league.id)
  # end
end
