class TeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  respond_to :html

  helper_method :team, :league

  def index
    # TODO: moved to MatchPlayers index
  end

  private

  def team
    @team ||= Team.find(params[:id])
  end

  def league
    @league ||= League.find(params[:league_id])
  end
end
