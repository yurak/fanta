class PlayersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  helper_method :player, :team

  respond_to :html

  # TODO: rename to #update
  def change_status
    status = params[:status]

    player.send("#{status}!")
    redirect_to team_path(team)
  end

  private

  def identifier
    params[:player_id].presence || params[:id]
  end

  def league
    @league ||= Team.find(params[:league_id])
  end

  def player
    @player ||= Player.find(identifier)
  end

  def player_params
    params.require(:player).permit(:name, :status)
  end
end
