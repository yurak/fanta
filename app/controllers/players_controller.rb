class PlayersController < ApplicationController
  before_action :authenticate_user!

  helper_method :player, :team

  respond_to :html

  def change_status
    status = params[:status]

    player.send("#{status}!")
    redirect_to team_path(team)
  end

  private

  def team
    @team ||= Team.find(params[:team_id])
  end

  def player
    @player ||= Player.find(params[:player_id])
  end

  def player_params
    params.require(:player).permit(:name, :status)
  end
end
