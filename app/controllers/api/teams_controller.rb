module Api
  class TeamsController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[show]

    respond_to :json

    helper_method :team

    def show
      if team
        render json: { data: TeamSerializer.new(team) }
      else
        not_found
      end
    end

    private

    def team
      @team ||= Team.find_by(id: params[:id])
    end
  end
end
