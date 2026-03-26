# frozen_string_literal: true

module Transfers
  class OutgoingProcessor < ApplicationService
    def initialize(league)
      @league = league
    end

    def call
      return false unless auction
      return false if auction.deadline.nil? || auction.deadline > Time.current

      process_transfers
      Auctions::Manager.call(auction, league.auction_type)
      true
    end

    private

    attr_reader :league

    def auction
      @auction ||= league.auctions.sales.last
    end

    def process_transfers
      ActiveRecord::Base.transaction do
        league.teams.each do |team|
          transferable = team.player_teams.transferable
          next if transferable.empty?

          team.update!(transfer_slots: team.transfer_slots - transferable.count)
          transferable.each { |pt| Transfers::Seller.call(pt.player, team, :outgoing) }
        end
      end
    end
  end
end
