module Admin
  class PlayersController < ApplicationController
    def create
      @player = Player.new(player_params)
      #@player.positions << Position.where(id: player_params[:position_ids])
      if @player.save
        redirect_to admin_users_path, notice: 'Player was successfully created.'
      else
        render :new
      end
    end

    def new
      @player = Player.new
    end

    private

    def player_params
      params.require(:player).permit(:name, :team_id, :club_id, position_ids: [])
    end
  end
end
