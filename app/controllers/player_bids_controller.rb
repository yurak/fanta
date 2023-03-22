class PlayerBidsController < ApplicationController
  respond_to :html, :json

  # helper_method :auction_bid, :auction_round, :dumped_player_ids, :league, :team

  def update
    if player_bid && player && player_available?
      player_bid.update(player: player)
    end

    head :ok
  end

  private

  def player_available?
    return false if team.dumped_player_ids(auction).include?(player.id)
    return false if player.teams.map(&:league_id).include?(league.id)

    true
  end

  def player_bid_params
    params.permit(:player_id)
  end

  def player_bid
    @player_bid ||= PlayerBid.find(params[:id])
  end

  def player
    @player ||= Player.find_by(id: player_bid_params[:player_id])
  end

  def team
    @team ||= current_user&.team_by_league(league)
  end

  def auction
    @auction ||= player_bid.auction_bid.auction
  end

  def league
    @league ||= auction.league
  end
end
