class AuctionRoundsController < ApplicationController
  respond_to :html

  helper_method :auction, :auction_bid, :auction_round, :league, :user_team

  def show
    if auction_round
      @transfers = top_transfers(auction.transfers.incoming)
      @drop_outs = top_transfers(auction.transfers.all_out)
      @modules = TeamModule.all
    else
      redirect_to leagues_path
    end
  end

  private

  def top_transfers(scope)
    scope.includes(:team, player: :club).sort_by(&:price).reverse.take(5)
  end

  def user_team
    return @user_team if defined?(@user_team)

    @user_team = current_user&.team_by_league(league)
    preload_team_players
    @user_team
  end

  def preload_team_players
    return unless @user_team

    ActiveRecord::Associations::Preloader.new(
      records: [@user_team], associations: { players: %i[club positions transfers] }
    ).call
  end

  def preload_bid_players
    return unless @auction_bid

    ActiveRecord::Associations::Preloader.new(
      records: [@auction_bid], associations: { player_bids: { player: [{ club: :tournament }, :positions] } }
    ).call
  end

  def auction_round
    return @auction_round if defined?(@auction_round)

    @auction_round = AuctionRound.find_by(id: params[:id])
  end

  def auction
    @auction ||= auction_round.auction
  end

  def auction_bid
    return unless current_user
    return @auction_bid if defined?(@auction_bid)

    @auction_bid = auction_round.auction_bids.find_by(team: current_user&.team_by_league(league))
    preload_bid_players
    @auction_bid
  end

  def league
    @league ||= auction.league
  end
end
