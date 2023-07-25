module AuctionRounds
  class Manager < ApplicationService
    attr_reader :round

    def initialize(auction_round)
      @round = auction_round
    end

    def call
      return false if round_not_ready?
      return false unless deadline_passed? || all_bids_completed?

      round.processing!

      manage_bids

      auction_bids.map(&:processed!)

      round.closed!

      true if vacancies? && AuctionRounds::Creator.call(auction)
    end

    private

    def manage_bids
      round.player_bids.initial.group_by(&:player_id).each do |player_group|
        player_bids = player_group[1].sort_by(&:price).reverse

        process_player_bids(player_bids)
      end

      round.player_bids.initial.map(&:failed!)
    end

    def process_player_bids(player_bids)
      if player_bids.count == 1
        process_bid(player_bids.first)
      else
        top_bids = player_bids.group_by(&:price).first[1]

        process_bid(top_bids.first) if top_bids.count == 1
      end
    end

    def process_bid(bid)
      unless bid.player.team_by_league(league.id)
        params = {
          auction_id: auction.id,
          player_id: bid.player.id,
          team_id: bid.auction_bid.team.id,
          price: bid.price
        }

        return if Transfers::Creator.call(league, params) && bid.success!
      end

      bid.failed!
    end

    def round_not_ready?
      !round.active? || round.deadline.nil? || league.teams.count.zero? || bids_not_ready?
    end

    def vacancies?
      league.players.count < league.teams.count * Team::MAX_PLAYERS
    end

    def deadline_passed?
      DateTime.now > round.deadline.asctime.in_time_zone('EET')
    end

    def bids_not_ready?
      auction_bids.any? { |ab| %w[submitted completed].exclude? ab.status }
    end

    def all_bids_completed?
      auction_bids.not_completed.empty?
    end

    def league
      @league ||= auction.league
    end

    def auction_bids
      @auction_bids ||= round.auction_bids
    end

    def auction
      @auction ||= round.auction
    end
  end
end
