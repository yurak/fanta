module Api
  class WishlistsController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[show]

    respond_to :json

    PRIVATE_KEY = 'wishlist_private'.freeze
    PRIVATE_MSG = 'This wishlist is private'.freeze

    def index
      wishlists = current_user.wishlists.by_season(season.id)
                              .includes(:tournament, :season, :wishlist_players, :user).order(:id)

      render json: { data: wishlists.map { |w| serialize(w) } }
    end

    def show
      return not_found unless wishlist
      return forbidden unless wishlist.readable_by?(current_user)

      render json: { data: serialize(wishlist) }
    end

    def update
      return not_found unless wishlist
      return forbidden unless wishlist.owned_by?(current_user)

      wishlist.update!(shared: ActiveModel::Type::Boolean.new.cast(params.require(:shared)))
      render json: { data: serialize(wishlist) }
    end

    private

    def wishlist
      return @wishlist if defined?(@wishlist)

      @wishlist = Wishlist.includes(:tournament, :season, :user).find_by(id: params[:id])
    end

    def serialize(record)
      WishlistSerializer.new(record, current_user: current_user)
    end

    def season
      @season ||= Season.last
    end

    def forbidden
      render json: { errors: [{ key: PRIVATE_KEY, message: PRIVATE_MSG }] }, status: :forbidden
    end
  end
end
