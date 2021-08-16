class TeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html, :json

  helper_method :team

  def show
    respond_to do |format|
      format.html
      format.json { render json: team.players.to_json }
    end
  end

  private

  def team
    @team ||= Team.find(params[:id])
  end
end
