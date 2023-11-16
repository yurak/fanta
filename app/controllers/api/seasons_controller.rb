module Api
  class SeasonsController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index]

    respond_to :json

    def index
      tournaments = Season.all.map { |t| SeasonSerializer.new(t) }
      render json: { data: tournaments }
    end
  end
end
