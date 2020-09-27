class ToursController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html, :json

  helper_method :tour, :tours, :league

  def show
    @tournament_players = tour.tournament_round.round_players.with_score.sort_by(&:result_score).reverse.take(5)
    @league_players = MatchPlayer.by_tour(tour.id).main.with_score.sort_by(&:total_score).reverse.take(5)
  end

  def edit
    redirect_to tour_path(tour) unless tour.set_lineup? && current_user&.admin?
    respond_with tour
  end

  def update
    flash[:notice] = 'Successfully updated tour' if tour.update(update_tour_params)

    redirect_to tour_path(tour)
  end

  def change_status
    tour_manager.call

    flash[:error] = "Status was not updated: #{tour_manager.tour.errors.full_messages.to_sentence}" if tour.errors.present?

    redirect_to tour_path(tour)
  end

  def inject_scores
    injector_klass.call(tournament_round: tour.tournament_round)
    Scores::PositionMalus::Updater.call(tour: tour)

    redirect_to tour_path(tour)
  end

  private

  def injector_klass
    @injector_klass ||= Scores::Injectors::Strategy.new(tour).klass
  end

  def identifier
    params[:tour_id].presence || params[:id]
  end

  def tour
    @tour ||= Tour.find(identifier)
  end

  def tours
    @tours = params[:closed] ? league.tours.closed_postponed.reverse : league.tours.inactive
  end

  def tour_manager
    @tour_manager ||= TourManager.new(tour: tour, status: params[:status])
  end

  def update_tour_params
    params.require(:tour).permit(:deadline)
  end

  def league
    @league ||= League.find(params[:league_id])
  end
end
