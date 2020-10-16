class LeaguesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  respond_to :html

  helper_method :leagues, :counters

  private

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
