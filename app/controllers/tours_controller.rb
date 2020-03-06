class ToursController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  respond_to :html, :json

  helper_method :tour, :tours, :league

  def index
    respond_with tours
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

  def edit_subs_scores
    redirect_to tour_path(tour) unless tour.closed? && (current_user&.admin? || current_user&.moderator?)
    @reservists = MatchPlayer.reservists_by_tour(tour.id)
    respond_with tour
  end

  def update_subs_scores
    match_players = update_reservists_params['match_players']
    match_players.keys.each do |mp_id|
      mp = MatchPlayer.find(mp_id.to_i)
      mp.update_attributes(match_players[mp_id].to_hash)
    end
    redirect_to tour_path(tour)
  end

  def inject_scores
    injector_klass.call(tour: tour)

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

  def update_reservists_params
    params.permit(match_players: %i[id score goals missed_goals scored_penalty failed_penalty cleansheet
                                    assists yellow_card red_card own_goals caught_penalty missed_penalty])
  end

  def league
    @league ||= League.find(params[:league_id])
  end
end
