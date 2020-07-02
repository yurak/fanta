class TeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html

  helper_method :team, :league

  private

  def team
    @team ||= Team.find(params[:id])
  end

  def league
    @league ||= League.find(params[:league_id])
  end
end
