module AuctionRounds
  class Manager < ApplicationService
    attr_reader :round

    def initialize(auction_round)
      @round = auction_round
    end

    def call
      return false if round_not_ready?
      return false unless round.ddl_expired? || all_bids_completed?

      AuctionRound.transaction do
        round.lock!
        next false unless round.active?

        round.processing!

        fit_bids_into_budget
        fail_bids_missing_gk
        fail_left_championship_player_bids

        manage_bids

        auction_bids.map(&:processed!)

        round.closed!

        process_auction
      end
    end

    private

    def fit_bids_into_budget
      auction_bids.each { |auction_bid| fit_bid_into_budget(auction_bid) }
    end

    def fit_bid_into_budget(auction_bid)
      excess = auction_bid.player_bids.sum(&:price) - budget_cap_for(auction_bid.team)
      return unless excess.positive?

      bids = auction_bid.player_bids.initial.select(&:player_id)
      return trim_to_budget(bids, excess) if first_stage? && trimmable?(bids, excess)

      auction_bid.player_bids.initial.map(&:failed!)
    end

    # A bid can only be trimmed down to the players' min prices — below that the whole bid is dropped.
    def trimmable?(bids, excess)
      bids.sum { |bid| bid.price - min_price_for(bid) } >= excess
    end

    # Takes the excess off the biggest bid first, moving on to the next one when it hits its min price.
    def trim_to_budget(bids, excess)
      while excess.positive?
        bid = bids.select { |b| b.price > min_price_for(b) }.min_by { |b| [-b.price, b.id] }
        cut = [bid.price - min_price_for(bid), excess].min
        bid.update(price: bid.price - cut)
        excess -= cut
      end
    end

    def min_price_for(bid)
      bid.player.stats_price
    end

    def budget_cap_for(team)
      first_stage? ? team.round_budget(round) : team.budget
    end

    def fail_bids_missing_gk
      min_gk = round.gk_min_limit
      return if min_gk.zero?

      auction_bids.each do |auction_bid|
        existing_gk = auction_bid.team.players.by_position(Position::GOALKEEPER).count
        bid_gk = auction_bid.player_bids.initial
                            .joins(player: :positions)
                            .where(positions: { name: Position::GOALKEEPER })
                            .count
        next if existing_gk + bid_gk >= min_gk

        auction_bid.player_bids.initial.map(&:failed!)
      end
    end

    def fail_left_championship_player_bids
      active_club_ids = league.tournament.clubs.active.pluck(:id)
      return if active_club_ids.empty?

      round.player_bids.initial.joins(:player).where.not(players: { club_id: active_club_ids }).find_each(&:failed!)
    end

    def manage_bids
      round.player_bids.initial.group_by(&:player_id).each do |player_group|
        player_bids = player_group[1].sort_by(&:price).reverse

        process_player_bids(player_bids)
      end

      round.player_bids.initial.map(&:failed!)
    end

    def process_auction
      if vacancies?
        notify_squad_complete
        AuctionRounds::Creator.call(auction)
      else
        Auctions::Manager.call(auction, Auctions::Manager::CLOSED_STATUS)
      end
    end

    def notify_squad_complete
      Notifications::Creator.call(notifiable: round, kind: :auction_squad_complete)
    end

    def process_player_bids(player_bids)
      if player_bids.one?
        process_bid(player_bids.first)
      else
        top_bids = player_bids.group_by(&:price).first[1]

        process_bid(top_bids.first) if top_bids.one?
      end
    end

    def process_bid(bid)
      if bid.player.present? && bid.player.team_by_league(league.id).nil?
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
      !round.active? || round.deadline.nil? || league.teams.none? || bids_not_ready?
    end

    def vacancies?
      league.players.count < league.teams.count * Team::MAX_PLAYERS
    end

    def bids_not_ready?
      return false unless auction.primary?
      return first_stage_bids_not_ready? if first_stage?

      auction_bids.any? { |ab| %w[submitted completed].exclude? ab.status }
    end

    def first_stage_bids_not_ready?
      round.player_bids.exists?(player_id: nil)
    end

    def first_stage?
      round.first? && auction.primary?
    end

    def all_bids_completed?
      auction_bids.not_completed.empty? && !(round.first? && auction.primary?)
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
