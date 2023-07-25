class ToursController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html, :json

  helper_method :tour

  def show
    redirect_to leagues_path unless tour

    @tournament_players = tour.round_players.with_score.sort_by(&:result_score).reverse.take(5)
    @league_players = MatchPlayer.by_tour(tour.id).main_with_score.sort_by(&:total_score).reverse.take(5)
  end

  def update
    tour_manager.call if can? :update, Tour

    redirect_to tour_path(tour)
  end

  # TODO: move action to RoundPlayersController#update
  def inject_scores
    if can? :inject_scores, Tour
      # TODO: temp removed
      # Tour.transaction do
      Scores::Injectors::Fotmob.call(tour.tournament_round)
      tour.tournament_round.tours.each do |tour|
        Scores::PositionMalus::Updater.call(tour)
        Lineups::Updater.call(tour)
      end
      # end
    end

    redirect_to tour_path(tour)
  end

  private

  def tour
    @tour ||= Tour.find(params[:id])
  end

  def tour_manager
    @tour_manager ||= Tours::Manager.new(tour, params[:status])
  end
end
