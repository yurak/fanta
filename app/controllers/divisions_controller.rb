class DivisionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  respond_to :html

  def index
    @leagues = League.includes(:division, results: :team).active.with_division.by_tournament(tournament.id)
                     .uniq.sort_by { |x| [x.division.id] }
  end

  private

  def divisions_params
    params.permit(:tournament_id).to_unsafe_h
  end

  def tournament
    @tournament ||= Tournament.find_by(id: divisions_params[:tournament_id])
  end
end
