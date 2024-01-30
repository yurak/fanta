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
      return unless auction.initial? && status == SALES_STATUS

      auction.sales!

      TelegramBot::AuctionSalesOpenNotifier.call(auction)
    end

    def blind_bids
      return unless (auction.initial? || auction.sales?) && status == BLIND_BIDS_STATUS

      Auction.transaction do
        AuctionRounds::Creator.call(auction)

        auction.blind_bids!
      end
    end

    def live
      auction.live! if (auction.initial? || auction.sales?) && status == LIVE_STATUS
    end

    def close
      auction.closed! if (auction.blind_bids? || auction.live?) && status == CLOSED_STATUS
    end
  end
end
