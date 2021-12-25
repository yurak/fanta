class TransfersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]

  respond_to :html

  helper_method :auction, :league

  def index
    @transfers = Kaminari.paginate_array(auction.transfers.reverse).page(params[:page])
  end

  def create
    creator = Transfers::Creator.call(league: league, params: create_params) if can? :create, Transfer
    player = transfer_player.id if !creator && transfer_player && !transfer_player.team_by_league(league.id)

    redirect_to league_auction_path(league, auction, player: player)
  end

  def destroy
    Transfers::Destroyer.call(transfer_id: params[:id]) if can? :destroy, Transfer

    redirect_to league_auction_path(league, auction)
  end

  private

  def auction
    @auction ||= Auction.find(params[:auction_id])
  end

  def league
    @league ||= League.find(params[:league_id])
  end

  def transfer_player
    @transfer_player ||= Player.find_by(id: create_params[:player_id])
  end

  def create_params
    return nil unless params[:transfer]

    params.require(:transfer).permit(:auction_id, :player_id, :team_id, :price)
  end
end
