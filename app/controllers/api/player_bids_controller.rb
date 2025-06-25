module Api
  class PlayerBidsController < ApplicationController
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
      @player_bid ||= PlayerBid.find_by(id: params[:id])
    end

    def auction
      @auction ||= player_bid.auction_bid.auction
    end
  end
end
