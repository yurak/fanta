class AuctionBidsController < ApplicationController
  respond_to :html, :json

  def show
    return redirect_to leagues_path unless bid_owner?

    @user_team = @auction_bid.team
    @modules = TeamModule.all
    @tournament = @auction_bid.team.join&.tournament
    return unless @auction_bid.auction_round

    @auction_round = @auction_bid.auction_round
    @league = @auction_round.auction.league
    @tournament = @league.tournament
    @auction = @auction_round.auction
    @transfers = @auction.transfers.incoming.sort_by(&:price).reverse.take(5)
    @drop_outs = @auction.transfers.all_out.sort_by(&:price).reverse.take(5)
  end

  def submit
    return redirect_to leagues_path unless bid_owner?

    join = auction_bid.team.join
    join.pending!
    redirect_to auction_bid_path(auction_bid), notice: t('join.submitted')
  end

  def update
    if params[:auction_round_id]
      AuctionBids::Manager.call(auction_bid, auction_bid_params) if editable?
      redirect_to auction_round_path(auction_round)
    else
      AuctionBids::Manager.call(auction_bid, auction_bid_params) if bid_owner?
      join = auction_bid.team.join
      if join && auction_bid.reload.submitted?
        join.pending!
        redirect_to join_path(join)
      else
        redirect_to auction_bid_path(auction_bid)
      end
    end
  end

  private

  def auction_bid_params
    params.fetch(:auction_bid, {}).permit(:status, player_bids_attributes: {})
  end

  def editable?
    return false unless team&.user

    team.user == current_user && team == auction_bid.team && auction_round.active?
  end

  def bid_owner?
    auction_bid&.team&.user == current_user
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
