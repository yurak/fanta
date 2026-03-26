# frozen_string_literal: true

module TelegramBot
  module Auction
    class RoundDdlBroadcaster < ApplicationService
      def call
        ::AuctionRound.active.each do |round|
          next unless round.auction.league.active?
          next if round.deadline.nil?
          next if Time.current < (round.deadline - 3.hours)
          next if Time.current > (round.deadline - 2.5.hours)

          Notifications::Creator.call(notifiable: round, kind: :auction_round_ddl)
        end
      end
    end
  end
end
