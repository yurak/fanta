module AuctionRounds
  class Manager < ApplicationService
    attr_reader :round

    def initialize(auction_round:)
      @round = auction_round
    end

    def call
      return false unless round.active?
      return false if round.deadline.nil? || round.deadline.asctime.in_time_zone('EET') > DateTime.now
      return false if league.teams.count.zero? || round.auction_bids.count < round.members.count

      round.processing!

      manage_bids

      round.closed!

      true if vacancies? && auction.auction_rounds.create(number: round.number + 1, deadline: round.deadline + 1.day)
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

        return if Transfers::Creator.call(league: league, params: params) && bid.success!
      end

      bid.failed!
    end

    def vacancies?
      league.players.count < league.teams.count * Team::MAX_PLAYERS
    end

    def league
      @league ||= auction.league
    end

    def auction
      @auction ||= round.auction
    end
  end
end
