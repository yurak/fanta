class PlayerRequestsController < ApplicationController
  respond_to :html

  helper_method :player

  def new
    @player_request = PlayerRequest.new
  end

  def create
    @player_request = PlayerRequest.new(player_request_params)
    if @player_request.save
      redirect_to player_path(player_request_params[:player_id])
    else
      render :new
    end
  end

  private

  def player
    @player ||= Player.find_by(id: params[:player_id])
  end

  def player_request_params
    params.require(:player_request).permit(:comment, :player_id, :user_id, { positions: [] })
  end
end
