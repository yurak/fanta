class ToursController < ApplicationController
  respond_to :html, :json

  helper_method :tours

  def index
    respond_with tours
  end

  def change_status
    tour_manager.call

    flash[:error] = "Status was not updated: #{tour_manager.tour.errors.full_messages.to_sentence}" if tour.errors.present?

    redirect_to tours_path
  end

  private

  def tour
    @tour ||= Tour.find(params[:tour_id])
  end

  def tour_manager
    @tour_manager ||= TourManager.new(tour: tour, status: params[:status])
  end

  def tours
    @tours ||= Tour.all
  end
end
