module Api
  class TournamentsController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index]

    respond_to :json

    def index
      show_clubs = params[:clubs] == 'true'
      tournaments = Tournament.active.map { |t| TournamentSerializer.new(t, clubs: show_clubs) }
      render json: { data: tournaments }
    end
  end
end
