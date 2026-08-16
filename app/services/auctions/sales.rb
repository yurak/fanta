module Auctions
  class Sales < ApplicationService
    TeamGroup = Struct.new(:team, :dropped, :left, :net_income, keyword_init: true)
    RankingEntry = Struct.new(:team, :value, keyword_init: true)

    TOP_LIMIT = 8

    def initialize(auction)
      @auction = auction
    end

    def call
      {
        teams: team_groups,
        top_earners: top_earners,
        top_droppers: top_droppers,
        top_sale: top_sale
      }
    end

    private

    attr_reader :auction

    def out_transfers
      @out_transfers ||= auction.transfers.all_out.includes(:team, player: %i[positions club]).to_a
    end

    def by_team_id
      @by_team_id ||= out_transfers.group_by(&:team_id)
    end

    def league_teams
      @league_teams ||= auction.league.teams.to_a
    end

    def team_groups
      @team_groups ||= league_teams.map { |team| build_group(team) }.sort_by { |group| -group.net_income }
    end

    def build_group(team)
      transfers = by_team_id[team.id] || []
      dropped, left = transfers.partition(&:outgoing?)
      TeamGroup.new(team: team, dropped: sort_by_price(dropped), left: sort_by_price(left),
                    net_income: transfers.sum(&:price))
    end

    def top_earners
      team_groups.map { |group| RankingEntry.new(team: group.team, value: group.net_income) }.first(TOP_LIMIT)
    end

    def top_droppers
      league_teams.map { |team| RankingEntry.new(team: team, value: (by_team_id[team.id] || []).size) }
                  .sort_by { |entry| -entry.value }.first(TOP_LIMIT)
    end

    def top_sale
      sort_by_price(out_transfers).first(TOP_LIMIT)
    end

    def sort_by_price(transfers)
      transfers.sort_by { |transfer| -transfer.price }
    end
  end
end
