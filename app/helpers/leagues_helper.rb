module LeaguesHelper
  def league_link(league)
    if league.active_tour
      tour_path(league.active_tour)
    elsif league.results.any?
      league_results_path(league)
    else
      league_path(league)
    end
  end
end
