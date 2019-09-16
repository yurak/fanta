class ToursController < ApplicationController
  respond_to :html, :json

  helper_method :tours, :tour

  def index
    respond_with tours
  end

  def change_status
    tour_manager.call

    flash[:error] = "Status was not updated: #{tour_manager.tour.errors.full_messages.to_sentence}" if tour.errors.present?

    redirect_to tours_path
  end

  def edit
    redirect_to tours_path unless tour.set_lineup? && current_user.admin?
    respond_with tour
  end

  def update
    flash[:notice] = 'Successfully updated tour' if tour.update(update_tour_params)

    redirect_to tours_path
  end

  private

  def identifier
    params[:tour_id].presence || params[:id]
  end

  def tour
    @tour ||= Tour.find(identifier)
  end

  def tour_manager
    @tour_manager ||= TourManager.new(tour: tour, status: params[:status])
  end

  def tours
    @tours ||= Tour.all.includes(:lineups, :matches)
  end

  def update_tour_params
    params.require(:tour).permit(:deadline)
  end
end
