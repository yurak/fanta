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

  def user_team_by_league(user, league)
    @user_team_by_league ||= user&.team_by_league(league)
  end
end
