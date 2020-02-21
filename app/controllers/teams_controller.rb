class TeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  respond_to :html

  helper_method :team

  def index
    @teams = Team.all

    respond_with @teams
  end

  def show; end

  private

  def team
    @team ||= Team.find(params[:id])
  end
end
