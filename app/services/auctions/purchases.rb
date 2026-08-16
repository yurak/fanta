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
        top_buy: top_buy
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
      @league_teams ||= auction.league.teams.to_a
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
  end
end
