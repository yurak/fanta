class AuctionsController < ApplicationController
  respond_to :html

  helper_method :auction, :league, :player, :players

  def index
    @auctions = league.auctions
  end

  def show
    return unless auction.closed?

    load_player_bid_groups
    @active_bid = @player_bid_groups.first&.last&.first
    @active_bid_logs = @is_transfer_auction ? {} : @active_bid&.player&.player_bids_by(auction.id)
  end

  def live
    redirect_to league_auction_transfers_path(league, auction) unless can? :live, Auction
  end

  def update
    auction_manager if can? :update, Auction

    redirect_to league_auctions_path(league)
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

  def auction_manager
    @auction_manager ||= Auctions::Manager.call(auction, params[:status])
  end

  def load_player_bid_groups
    @player_bid_groups = PlayerBids::Search.call(search_params.merge(auction_id: auction.id))
    return unless @player_bid_groups.empty?

    @player_bid_groups = { 1 => auction_transfers }
    @is_transfer_auction = true
  end

  def auction_transfers
    transfers = auction.transfers.incoming.includes(:team, player: %i[positions club]).order(price: :desc)
    if params[:search].present?
      transfers = transfers.joins(:player)
                           .where('lower(players.name) LIKE :q OR lower(players.first_name) LIKE :q',
                                  q: "%#{params[:search].downcase}%")
    end
    if params[:position].present?
      transfers = transfers.joins(player: { player_positions: :position })
                           .where(positions: { human_name: params[:position] })
    end
    transfers = transfers.where(team_id: params[:team_id]) if params[:team_id].present?
    transfers.to_a
  end

  def search_params
    params.permit(:id, :league_id, :position, :round, :search, :team_id).to_unsafe_h
  end
end
