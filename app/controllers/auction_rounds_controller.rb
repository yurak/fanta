class AuctionRoundsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html

  helper_method :auction, :auction_round, :league

  def show
    @transfers = auction.transfers.incoming.sort_by(&:price).reverse.take(5)
  end

  private

  def auction_round
    @auction_round ||= AuctionRound.find(params[:id])
  end

  def auction
    @auction ||= auction_round.auction
  end

  def league
    @league ||= auction.league
  end
end
