class ToursController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html, :json

  helper_method :tour

  def show
    if tour
      @tournament_players = tour.round_players.with_score.sort_by(&:result_score).reverse.take(5)
      @league_players = MatchPlayer.by_tour(tour.id).main_with_score.sort_by(&:total_score).reverse.take(5)
    else
      redirect_to leagues_path
    end
  end

  def update
    tour_manager.call if can? :update, Tour

    redirect_to tour_path(tour)
  end

  def preview; end

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
    @tour ||= Tour.find_by(id: params[:id])
  end

  def tournament_round
    @tournament_round ||= tour.tournament_round
  end

  def tour_manager
    @tour_manager ||= Tours::Manager.new(tour, params[:status])
  end
end
