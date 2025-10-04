class ToursController < ApplicationController
  respond_to :html, :json

  helper_method :tour

  def show
    if tour
      @results_ordered = tour.league.results.includes(:team).ordered
      @results_by_score = tour.league.results.includes(:team).ordered_by_score.limit(5)
      @matches = tour.tournament_round.tournament_matches.includes(:host_club, :guest_club)
    else
      redirect_to leagues_path
    end
  end

  def tournament_players
    if tour
      @tournament_players = tour.round_players.with_score.includes(player: %i[positions teams])
                                .sort_by { |rp| -rp.result_score }.take(5)

      @teams_by_player = {}
      @tournament_players.each do |r_player|
        team = r_player.teams.detect { |t| t.league_id == tour.league_id }
        @teams_by_player[r_player.id] = team
      end

      respond_to do |format|
        format.html { render partial: 'tours/tournament_players', layout: false }
      end
    else
      redirect_to leagues_path
    end
  end

  def league_players
    if tour
      @league_players = MatchPlayer.by_tour(tour.id).main_with_score
                                   .includes(round_player: { player: %i[positions teams] }, lineup: :team)
                                   .sort_by { |mp| -mp.total_score }.take(5)

      @teams_by_player = {}
      @league_players.each do |r_player|
        team = r_player.teams.detect { |t| t.league_id == tour.league_id }
        @teams_by_player[r_player.id] = team
      end

      respond_to do |format|
        format.html { render partial: 'tours/league_players', layout: false }
      end
    else
      redirect_to leagues_path
    end
  end

  def update
    tour_manager.call if can? :update, Tour

    redirect_to tour_path(tour)
  end

  # TODO: move action to TournamentRoundController#inject_scores or RoundPlayersController#update
  def inject_scores
    if can? :inject_scores, Tour
      # TODO: temp removed
      # Tour.transaction do
      injector = "Scores::Injectors::#{tournament_round.tournament.source.capitalize}".constantize
      injector.call(tournament_round)
      tournament_round.tours.each do |tour|
        Scores::PositionMalus::Updater.call(tour)
        Lineups::Updater.call(tour)
      end
      # end
    end

    path = params['redirect'] == 'round' ? tournament_round_path(tournament_round) : tour_path(tour)
    redirect_to path
  end

  private

  def tour
    @tour ||= Tour.includes(
      league: { results: :team },
      tournament_round: { tournament_matches: %i[host_club guest_club] }
    ).find_by(id: params[:id])
  end

  def tournament_round
    @tournament_round ||= tour.tournament_round
  end

  def tour_manager
    @tour_manager ||= Tours::Manager.new(tour, params[:status])
  end
end
