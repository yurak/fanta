module Api
  class LeaguesController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index]

    respond_to :json

    def index
      leagues = League.serial.map { |l| LeagueSerializer.new(l) }
      render json: { data: leagues }
    end
  end
end
