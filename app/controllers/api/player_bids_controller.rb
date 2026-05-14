module Api
  class PlayerBidsController < Api::ApplicationController
    skip_before_action :authenticate_user!, only: %i[show]

    respond_to :json

    helper_method :player_bid

    def show
      if player_bid && auction.closed?
        render json: { data: PlayerBidSerializer.new(player_bid) }
      else
        not_found
      end
    end

    private

    def player_bid
      return @player_bid if defined?(@player_bid)

      @player_bid = PlayerBid.includes(player: [{ player_positions: :position }, :club]).find_by(id: params[:id])
    end

    def auction
      @auction ||= player_bid.auction_bid.auction
    end
  end
end
