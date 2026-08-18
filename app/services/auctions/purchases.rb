module Auctions
  class Purchases < ApplicationService
    TeamGroup = Struct.new(:team, :bought, :total_spent, keyword_init: true)
    RankingEntry = Struct.new(:team, :value, keyword_init: true)

    TOP_LIMIT = 8

    def initialize(auction)
      @auction = auction
    end

    def call
      {
        teams: team_groups,
        top_spenders: top_spenders,
        top_buy: top_buy,
        stages: stages,
        stage_by: stage_by
      }
    end

    private

    attr_reader :auction

    def in_transfers
      @in_transfers ||= auction.transfers.incoming.includes(:team, player: %i[positions club]).to_a
    end

    def by_team_id
      @by_team_id ||= in_transfers.group_by(&:team_id)
    end

    def league_teams
      @league_teams ||= auction.league.results.includes(:team).map(&:team)
    end

    def team_groups
      @team_groups ||= league_teams.map { |team| build_group(team) }.sort_by { |group| -group.total_spent }
    end

    def build_group(team)
      transfers = by_team_id[team.id] || []
      TeamGroup.new(team: team, bought: sort_by_price(transfers), total_spent: transfers.sum(&:price))
    end

    def top_spenders
      team_groups.map { |group| RankingEntry.new(team: group.team, value: group.total_spent) }.first(TOP_LIMIT)
    end

    def top_buy
      sort_by_price(in_transfers).first(TOP_LIMIT)
    end

    def sort_by_price(transfers)
      transfers.sort_by { |transfer| -transfer.price }
    end

    def stages
      @stages ||= auction.auction_rounds.map(&:number)
    end

    def stage_by
      @stage_by ||= in_transfers.to_h { |transfer| [transfer.id, winning_rounds[[transfer.player_id, transfer.team_id]]] }
    end

    def winning_rounds
      @winning_rounds ||= PlayerBid.success
                                   .joins(auction_bid: :auction_round)
                                   .where(auction_rounds: { auction_id: auction.id }, player_id: in_transfers.map(&:player_id))
                                   .pluck(:player_id, 'auction_bids.team_id', 'auction_rounds.number')
                                   .each_with_object({}) { |(player_id, team_id, number), memo| memo[[player_id, team_id]] = number }
    end
  end
end
