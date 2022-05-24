class ToursController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html, :json

  helper_method :auction, :tour

  def show
    redirect_to leagues_path unless tour

    @tournament_players = tour.tournament_round.round_players.with_score.sort_by(&:result_score).reverse.take(5)
    @league_players = MatchPlayer.by_tour(tour.id).main.with_score.sort_by(&:total_score).reverse.take(5)
  end

  def update
    tour_manager.call if can? :update, Tour

    redirect_to tour_path(tour)
  end

  def inject_scores
    if can? :inject_scores, Tour
      injector_klass.call(tournament_round: tour.tournament_round)
      Scores::PositionMalus::Updater.call(tour: tour)
    end

    redirect_to tour_path(tour)
  end

  private

  def injector_klass
    @injector_klass ||= Scores::Injectors::Strategy.call(tour)
  end

  def tour
    @tour ||= Tour.find(params[:id])
  end

  def tour_manager
    @tour_manager ||= Tours::Manager.new(tour: tour, status: params[:status])
  end

  def auction
    @auction ||= tour.league.auctions.active.last
  end
end
