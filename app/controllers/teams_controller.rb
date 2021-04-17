class TeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html

  helper_method :team, :league

  def show; end

  private

  def team
    @team ||= Team.find(params[:id])
  end
end
