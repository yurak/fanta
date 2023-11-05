module Api
  class LeaguesController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index]

    respond_to :json

    def index
      active_leagues = League.active.serial.map { |l| LeagueSerializer.new(l) }
      active_tournaments = Tournament.active.map { |t| TournamentSerializer.new(t) }
      render json: { leagues: active_leagues, tournaments: active_tournaments }
    end
  end
end
