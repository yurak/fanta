module Api
  class WishlistPlayersController < ApplicationController
    respond_to :json

    FULL_KEY = 'wishlist_full'.freeze
    NOT_ALLOWED_KEY = 'wishlist_not_allowed'.freeze

    def create
      store(wanted: true)
    end

    def destroy
      store(wanted: false)
    end

    private

    def store(wanted:)
      return not_found unless player

      result = Wishlists::PlayerUpdater.call(user: current_user, player: player, wanted: wanted)
      return error(result.error) unless result.ok?

      render json: { data: payload(result) }
    end

    def payload(result)
      {
        player_id: player.id,
        wishlisted: result.wishlisted,
        wishlist: WishlistSerializer.new(result.wishlist, current_user: current_user)
      }
    end

    def player
      return @player if defined?(@player)

      @player = Player.includes(club: :tournament).find_by(id: params[:player_id] || params[:id])
    end

    def error(reason)
      key = reason == :full ? FULL_KEY : NOT_ALLOWED_KEY
      status = reason == :full ? :unprocessable_entity : :forbidden

      render json: { errors: [{ key: key, message: message_for(reason) }] }, status: status
    end

    def message_for(reason)
      return "A wishlist holds at most #{Wishlist::MAX_PLAYERS} players" if reason == :full

      'This player cannot be wishlisted'
    end
  end
end
