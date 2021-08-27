module LeaguesHelper
  def league_link(league)
    league.active_tour ? tour_path(league.active_tour) : league_results_path(league)
  end
end
