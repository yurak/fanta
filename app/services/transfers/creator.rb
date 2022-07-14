module Transfers
  class Creator < ApplicationService
    attr_reader :league, :params

    def initialize(league, params)
      @league = league
      @params = params
    end

    def call
      return false unless valid_transfer?

      ActiveRecord::Base.transaction do
        league.transfers.create(params)
        PlayerTeam.create(team: team, player: player)
        team.update(budget: team.budget - price)
      end
    end

    private

    def team
      @team ||= Team.find_by(id: params[:team_id])
    end

    def price
      @price ||= params[:price].to_i
    end

    def player
      @player ||= Player.find_by(id: params[:player_id])
    end

    def valid_transfer?
      return false unless player
      return false unless team
      return false if team.full_squad?
      return false if price > team.max_rate || price < 1
      return false if player&.team_by_league(league.id)

      true
    end
  end
end
