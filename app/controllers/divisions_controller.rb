class DivisionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  respond_to :html

  def index
    @leagues = League.joins(:division).by_season(season.id).by_tournament(tournament.id).order('divisions.level')
                     .group_by { |league| league.division.level }
  end

  private

  def divisions_params
    params.permit(:tournament_id).to_unsafe_h
  end

  def tournament
    @tournament ||= Tournament.find_by(id: divisions_params[:tournament_id])
  end

  def season
    @season ||= Season.last
  end
end
