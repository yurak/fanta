module Wishlists
  class PlayerUpdater < ApplicationService
    Result = Struct.new(:wishlisted, :wishlist, :error, keyword_init: true) do
      def ok?
        error.nil?
      end
    end

    attr_reader :user, :player, :wanted

    def initialize(user:, player:, wanted:)
      @user = user
      @player = player
      @wanted = wanted
    end

    def call
      return failure(:not_allowed) unless self.class.allowed?(player)

      wishlist = Wishlist.fetch_or_create(user: user, tournament: tournament, season: season)

      wanted ? add(wishlist) : remove(wishlist)
    end

    def self.allowed?(player)
      tournament = player&.club&.tournament

      tournament.present? && tournament.mantra?
    end

    private

    def tournament
      player.club.tournament
    end

    def season
      @season ||= Season.last
    end

    def add(wishlist)
      return present(wishlist) if stored(wishlist)
      return failure(:full, wishlist) if wishlist.full?

      wishlist.wishlist_players.create!(player: player)
      present(wishlist)
    rescue ActiveRecord::RecordNotUnique
      present(wishlist)
    end

    def remove(wishlist)
      stored(wishlist)&.destroy

      Result.new(wishlisted: false, wishlist: wishlist)
    end

    def stored(wishlist)
      wishlist.wishlist_players.find_by(player_id: player.id)
    end

    def present(wishlist)
      Result.new(wishlisted: true, wishlist: wishlist)
    end

    def failure(error, wishlist = nil)
      Result.new(wishlisted: false, wishlist: wishlist, error: error)
    end
  end
end
