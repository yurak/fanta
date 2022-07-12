module Auctions
  class Manager < ApplicationService
    BLIND_BIDS_STATUS = 'blind_bids'.freeze
    CLOSED_STATUS = 'closed'.freeze
    INITIAL_STATUS = 'initial'.freeze
    LIVE_STATUS = 'live'.freeze
    SALES_STATUS = 'sales'.freeze

    attr_reader :auction, :status

    def initialize(auction, status)
      @auction = auction
      @status = status
    end

    def call
      sales

      blind_bids

      live

      close
    end

    private

    def sales
      auction.sales! if auction.initial? && status == SALES_STATUS
    end

    def blind_bids
      return unless (auction.initial? || auction.sales?) && status == BLIND_BIDS_STATUS

      create_auction_round

      auction.blind_bids!
    end

    def live
      auction.live! if (auction.initial? || auction.sales?) && status == LIVE_STATUS
    end

    def close
      auction.closed! if (auction.blind_bids? || auction.live?) && status == CLOSED_STATUS
    end

    def create_auction_round
      auction.auction_rounds.create(
        number: auction.auction_rounds.count + 1,
        deadline: (auction.deadline.presence || Time.zone.now) + 1.day
      )
    end
  end
end
