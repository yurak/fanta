module Api
  class TeamsController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index show]

    respond_to :json

    helper_method :team

    def index
      teams = League.find_by(id: params[:league_id])&.teams&.order(:human_name) || []
      render json: { data: teams.map { |t| TeamSlimSerializer.new(t) } }
    end

    def show
      if team
        render json: { data: TeamSerializer.new(team) }
      else
        not_found
      end
    end

    private

    def team
      return @team if defined?(@team)

      @team = Team.find_by(id: params[:id])
    end
  end
end
