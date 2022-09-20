class LeaguesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  respond_to :html

  helper_method :counters, :league, :leagues

  def index; end

  def show; end

  private

  def league
    @league ||= League.find(params[:id])
  end

  def leagues
    leagues = {}
    leagues['registration'] = [] # League.initial
    leagues['ongoing'] = League.active.includes(:results).sort_by(&:tournament_id)
    leagues['finished'] = League.archived.includes(:results).sort_by(&:season_id)
    leagues
  end

  def counters
    # TODO: temp
    # counters = {}
    # leagues.each do |type, leagues|
    #   counters[type] = League.counters(leagues)
    # end
    # counters
  end
end
