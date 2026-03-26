# frozen_string_literal: true

module TelegramBot
  module Auction
    class SalesDdlBroadcaster < ApplicationService
      def call
        ::League.active.each do |league|
          auction = league.auctions.sales.last

          next unless auction
          next if auction.deadline.nil?
          next if Time.current < (auction.deadline - 18.hours)

          Notifications::Creator.call(notifiable: auction, kind: :auction_sales_ddl)
        end
      end
    end
  end
end
