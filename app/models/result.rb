class Result < ApplicationRecord
  belongs_to :team

  delegate :lineups, to: :team

  def matches_played
    @matches_played ||= wins + draws + loses
  end

  def goals_difference
    @goals_difference ||= scored_goals - missed_goals
  end

  def form
    @form ||= lineups.closed.limit(5).map(&:result)
  end
end
