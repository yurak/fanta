class PlayerBidsController < ApplicationController
  respond_to :html, :json

  def update
    if player_bid && player && auction_round.active? && player_available?
      player_bid.auction_bid.ongoing! if player_bid.auction_bid.submitted?
      player_bid.update(player_bid_params)
    end

    render json: player
  end

  private

  def player_available?
    return false if team.dumped_player_ids(auction).include?(player.id)
    return false if player.teams.map(&:league_id).include?(league.id)

    true
  end

  def player_bid_params
    params.permit(:player_id, :price)
  end

  def player_bid
    @player_bid ||= PlayerBid.find(params[:id])
  end

  def player
    @player ||= Player.find_by(id: player_bid_params[:player_id] || player_bid.player_id)
  end

  def team
    @team ||= current_user&.team_by_league(league)
  end

  def auction
    @auction ||= auction_round.auction
  end

  def auction_round
    @auction ||= player_bid.auction_bid.auction_round
  end

  def league
    @league ||= auction.league
  end
end
