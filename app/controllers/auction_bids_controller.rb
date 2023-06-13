class AuctionBidsController < ApplicationController
  respond_to :html, :json

  def update
    AuctionBids::Manager.call(auction_bid, auction_bid_params) if editable?

    redirect_to auction_round_path(auction_round)
  end

  private

  def auction_bid_params
    params.fetch(:auction_bid, {}).permit(:status, player_bids_attributes: {})
  end

  def editable?
    return false unless team&.user

    team.user == current_user && team == auction_bid.team && auction_round.active?
  end

  def auction_bid
    @auction_bid ||= AuctionBid.find_by(id: params[:id])
  end

  def auction_round
    @auction_round ||= AuctionRound.find(params[:auction_round_id])
  end

  def team
    @team ||= current_user&.team_by_league(auction_round.league)
  end
end
