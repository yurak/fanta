class ClubsController < ApplicationController
  respond_to :html

  def index
    # TODO: add ordering by params; params[:order]

    @players = Player.all.stats_query
    @clubs = Club.all.order_by_players_count
  end
end
