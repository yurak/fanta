class ToursController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html, :json

  helper_method :tour

  def show
    @tournament_players = tour.tournament_round.round_players.with_score.sort_by(&:result_score).reverse.take(5)
    @league_players = MatchPlayer.by_tour(tour.id).main.with_score.sort_by(&:total_score).reverse.take(5)
  end

  def edit
    redirect_to tour_path(tour) unless tour.set_lineup? && (can? :edit, Tour)
  end

  def update
    tour.update(update_tour_params) if can? :update, Tour

    redirect_to tour_path(tour)
  end

  def change_status
    tour_manager.call if can? :change_status, Tour

    flash[:error] = "Status was not updated: #{tour_manager.tour.errors.full_messages.to_sentence}" if tour.errors.present?

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
    @injector_klass ||= Scores::Injectors::Strategy.new(tour).klass
  end

  def tour
    @tour ||= Tour.find(params[:id])
  end

  def tour_manager
    @tour_manager ||= Tours::Manager.new(tour: tour, status: params[:status])
  end

  def update_tour_params
    params.require(:tour).permit(:deadline)
  end
end
