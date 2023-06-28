module AuctionRounds
  class Creator < ApplicationService
    attr_reader :auction

    def initialize(auction)
      @auction = auction
    end

    def call
      return false unless auction
      return false if auction.league.teams.empty?

      @auction_round = create_auction_round

      create_auction_bids

      TelegramBot::AuctionStartBidsNotifier.call(auction)
    end

    private

    def create_auction_round
      auction.auction_rounds.create(
        number: auction.auction_rounds.count + 1,
        deadline: (auction.deadline.presence || Time.zone.now) + 1.day
      )
    end

    def create_auction_bids
      auction.league.teams.each do |team|
        next if team.full_squad?

        auction_bid = @auction_round.auction_bids.create(team: team)

        team.vacancies.times { |_| auction_bid.player_bids.create }
      end
    end
  end
end
