class DivisionsController < ApplicationController
  respond_to :html

  def index
    @leagues = League.eager_load(:division).by_season(season.id).by_tournament(tournament.id)
                     .where.not(division_id: nil).order('divisions.level')
                     .group_by { |league| league.division.level }
  end

  private

  def divisions_params
    params.permit(:tournament_id).to_unsafe_h
  end

  def tournament
    return @tournament if defined?(@tournament)

    @tournament = Tournament.find_by(id: divisions_params[:tournament_id])
  end

  def season
    @season ||= Season.last
  end
end
