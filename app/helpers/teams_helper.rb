module TeamsHelper
  def team_league_link(league)
    return '' unless league

    league.active_tour ? tour_path(league.active_tour) : league_results_path(league)
  end
end
