class AuctionsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]

  respond_to :html

  helper_method :auction, :league, :player, :players

  def index
    @auctions = league.auctions
  end

  def show
    redirect_to league_auction_transfers_path(league, auction) unless can? :show, Auction
  end

  private

  def auction
    @auction ||= Auction.find(params[:id])
  end

  def league
    @league ||= League.find(params[:league_id])
  end

  def player
    @player ||= Player.find_by(id: params[:player])
  end

  def players
    @players ||= Player.by_tournament(league.tournament).search_by_name(params[:search]) if params[:search].present?
  end
end
