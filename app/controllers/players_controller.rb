class PlayersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  helper_method :player, :team

  respond_to :html

  def show
    respond_to do |format|
      format.html
      format.json { render json: player, serializer: PlayerSerializer }
    end
  end

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

  def team
    @team ||= Team.find(params[:team_id])
  end

  def player
    @player ||= Player.find(identifier)
  end

  def player_params
    params.require(:player).permit(:name, :status)
  end
end
