class AuctionBidsController < ApplicationController
  respond_to :html, :json

  def show
    return redirect_to leagues_path unless bid_owner?

    @auction_bid = AuctionBid.includes(player_bids: { player: [:positions, { club: :tournament }] }).find(@auction_bid.id)
    @user_team = @auction_bid.team
    @modules = TeamModule.all
    @tournament = @auction_bid.join&.tournament
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

    join = auction_bid.join
    join&.pending!
    redirect_to auction_bid_path(auction_bid), notice: t('join.submitted')
  end

  def generate
    return redirect_to leagues_path unless bid_owner?

    if auction_bid.auction_round_id.nil? && auction_bid.editable?
      AuctionBids::LineupGenerator.call(auction_bid)
    else
      log_rejected('bid_not_editable', bid: auction_bid.id, status: auction_bid.status,
                                       round: auction_bid.auction_round_id)
    end

    redirect_to auction_bid_path(auction_bid)
  end

  def update
    return update_round_bid if params[:auction_round_id]

    update_own_bid
  end

  private

  def update_round_bid
    if editable?
      AuctionBids::Manager.call(auction_bid, auction_bid_params)
    else
      log_rejected(bid_rejection, team: team&.id, round: auction_round.id,
                                  round_status: auction_round.status,
                                  deadline: auction_round.deadline&.iso8601)
    end

    redirect_to auction_round_path(auction_round)
  end

  def update_own_bid
    if bid_owner?
      AuctionBids::Manager.call(auction_bid, auction_bid_params)
    else
      log_rejected('foreign_team', bid: auction_bid&.id)
    end

    join = auction_bid.join
    return redirect_to(auction_bid_path(auction_bid)) unless join && auction_bid.reload.submitted?

    join.pending!
    redirect_to join_path(join)
  end

  def auction_bid_params
    params.fetch(:auction_bid, {}).permit(:status, player_bids_attributes: {})
  end

  def editable?
    return false unless team&.user

    team.user == current_user && team == auction_bid.team && auction_round.editable?
  end

  def bid_owner?
    auction_bid&.team&.user == current_user
  end

  def bid_rejection
    return 'foreign_team' unless team&.user == current_user && team == auction_bid&.team
    return 'ddl_expired' if auction_round.ddl_expired?

    'round_closed'
  end

  def auction_bid
    return @auction_bid if defined?(@auction_bid)

    @auction_bid = AuctionBid.find_by(id: params[:id])
  end

  def auction_round
    @auction_round ||= AuctionRound.find(params.expect(:auction_round_id))
  end

  def team
    @team ||= current_user&.team_by_league(auction_round.league)
  end
end
