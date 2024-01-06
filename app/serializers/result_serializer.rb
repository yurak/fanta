class ResultSerializer < ActiveModel::Serializer
  attributes :id
  attributes :best_lineup
  attributes :draws
  attributes :form
  attributes :goals_difference
  attributes :history
  attributes :league_id
  attributes :loses
  attributes :matches_played
  attributes :missed_goals
  attributes :next_opponent_id
  attributes :points
  attributes :scored_goals
  attributes :team
  attributes :total_score
  attributes :wins

  def form
    # object.form
    object.closed_lineups.limit(5).reverse.map(&:result) if object.league.mantra?
  end

  def history
    JSON.parse(object.history)
  end

  def next_opponent_id
    object.team.next_opponent&.id
  end

  def team
    TeamSerializer.new(object.team)
  end
end
