module Transfers
  class Seller < ApplicationService
    attr_reader :player, :team, :status

    def initialize(player:, team:, status:)
      @player = player
      @team = team
      @status = status
    end

    def call
      return unless init_transfer && player_team && auction

      ActiveRecord::Base.transaction do
        create_transfer
        team.update(budget: team.budget + init_transfer.price)
        player_team.destroy
      end
    end

    private

    def create_transfer
      Transfer.create(player: player, team: team, league: team.league, auction: auction, price: init_transfer.price, status: status)
    end

    def init_transfer
      @init_transfer ||= player.transfer_by(team)
    end

    def player_team
      @player_team ||= player.player_teams.find_by(team: team)
    end

    def auction
      @auction ||= team.league.auctions.initial_sales.first
    end
  end
end
