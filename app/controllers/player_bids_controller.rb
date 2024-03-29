class PlayerBidsController < ApplicationController
  respond_to :html, :json

  def update
    if valid_update?
      auction_bid.ongoing! if auction_bid.submitted?

      bid = player_bid_params
      bid = bid.merge(price: player.stats_price) if auction_round.basic? && bid[:price].to_i < player.stats_price

      player_bid.update(bid)
    end

    render json: player
  end

  private

  def valid_update?
    player_bid && player && auction_round.active? && player_available? && auction_bid.editable?
  end

  def player_available?
    return false unless team && team == auction_bid.team
    return false if team.dumped_player_ids(auction).include?(player.id)
    return false if player.teams.map(&:league_id).include?(league.id)

    true
  end

  def player_bid_params
    params.permit(:player_id, :price).to_unsafe_h
  end

  def player_bid
    @player_bid ||= PlayerBid.find_by(id: params[:id])
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

  def auction_bid
    @auction_bid ||= player_bid.auction_bid
  end

  def auction_round
    @auction_round ||= auction_bid.auction_round
  end

  def league
    @league ||= auction.league
  end
end
