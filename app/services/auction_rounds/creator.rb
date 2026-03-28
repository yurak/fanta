module AuctionRounds
  class Creator < ApplicationService
    attr_reader :auction

    def initialize(auction)
      @auction = auction
    end

    def call
      return false unless auction
      return false if league.teams.empty?

      @auction_round = create_auction_round

      create_auction_bids

      Notifications::Creator.call(notifiable: @auction_round, kind: :auction_start_bids)

      true
    end

    private

    def create_auction_round
      auction.auction_rounds.create(
        number: auction.auction_rounds.count + 1,
        deadline: next_deadline,
        basic: basic?
      )
    end

    def next_deadline
      base = auction.auction_rounds.last&.deadline || auction.deadline.presence || Time.zone.now
      base > 1.day.from_now ? base : base + 1.day
    end

    def basic?
      auction.primary? && auction.auction_rounds.count.zero?
    end

    def league
      @league ||= auction.league
    end

    def create_auction_bids
      league.teams.each do |team|
        next if team.full_squad?

        auction_bid = @auction_round.auction_bids.create(team: team)

        @auction_round.slots_number_by(team).times { |_| auction_bid.player_bids.create }

        auction_bid.lock_player_bids!
      end
    end
  end
end
