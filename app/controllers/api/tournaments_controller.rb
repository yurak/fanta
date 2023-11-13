module Api
  class TournamentsController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index]

    respond_to :json

    def index
      tournaments = Tournament.active.map { |t| TournamentSerializer.new(t) }
      render json: { data: tournaments }
    end
  end
end
