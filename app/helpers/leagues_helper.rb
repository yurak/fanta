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

  def league_round_tour(league)
    page_tour = current_page_tour

    page_tour&.league_id == league.id ? page_tour : league.active_tour
  end

  def current_page_tour
    return tour if respond_to?(:tour) && tour.is_a?(Tour)
    return match.tour if respond_to?(:match) && match.respond_to?(:tour)

    nil
  end

  def user_team_by_league(user, league)
    @user_team_by_league ||= user&.team_by_league(league)
  end
end
