class LeaguesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  respond_to :html

  helper_method :auction, :league, :leagues, :counters

  def index; end

  def show; end

  private

  def league
    @league ||= League.find(params[:id])
  end

  def auction
    @auction ||= league.auctions.active.last
  end

  def leagues
    leagues = {}
    leagues['registration'] = [] # TODO
    leagues['ongoing'] = League.active
    leagues['finished'] = League.archived
    leagues
  end

  def counters
    counters = {}
    leagues.each do |type, leagues|
      counters[type] = League.counters(leagues)
    end
    counters
  end
end
