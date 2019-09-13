class ClubsController < ApplicationController
  respond_to :html

  def index
    # status = params[:status]

    @players = Player.all
    @clubs = Club.all
  end
end
