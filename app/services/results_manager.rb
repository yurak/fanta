class ResultsManager
  attr_reader :tour

  def initialize(tour: nil)
    @tour = tour
  end

  def create
    Team.all.each do |team|
      Result.create(team_id: team.id)
    end
  end

  def update
    tour.matches.each do |match|
      if match.host_win?
        update_result_win(match, match.host, match.guest)
      elsif match.guest_win?
        update_result_win(match, match.guest, match.host)
      elsif match.draw?
        update_result_draw(match, match.host)
        update_result_draw(match, match.guest)
      end
    end
  end

  private

  def update_result_win(match, winner, loser)
    winner.result.update(
      points: winner.result.points + 3,
      wins: winner.result.wins + 1,
      scored_goals: winner.result.scored_goals + match.scored_goals(winner),
      missed_goals: winner.result.missed_goals + match.missed_goals(winner)
    )
    loser.result.update(
      loses: loser.result.loses + 1,
      scored_goals: loser.result.scored_goals + match.scored_goals(loser),
      missed_goals: loser.result.missed_goals + match.missed_goals(loser)
    )
  end

  def update_result_draw(match, team)
    team.result.update(
      points: team.result.points + 1,
      draws: team.result.draws + 1,
      scored_goals: team.result.scored_goals + match.scored_goals(team),
      missed_goals: team.result.missed_goals + match.missed_goals(team)
    )
  end
end
