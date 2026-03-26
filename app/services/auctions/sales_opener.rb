# frozen_string_literal: true

module Auctions
  class SalesOpener < ApplicationService
    def initialize(auction)
      @auction = auction
    end

    def call
      return false unless auction.deadline
      return false if auction.primary?
      return false if hours_until_deadline > Auction::HOURS_FOR_SALES

      Auctions::Manager.call(auction, Auctions::Manager::SALES_STATUS)
      true
    end

    private

    attr_reader :auction

    def hours_until_deadline
      ((auction.deadline - Time.zone.now) / 3_600).to_i
    end
  end
end
