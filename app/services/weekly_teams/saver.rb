module WeeklyTeams
  class Saver < ApplicationService
    def initialize(team_module_id:, round_ids:, mode:, number:, players:)
      @team_module_id = team_module_id
      @round_ids      = round_ids
      @mode           = mode
      @number         = number
      @players        = players
    end

    def call
      weekly_team = build_weekly_team
      return nil unless weekly_team.valid?

      ActiveRecord::Base.transaction do
        weekly_team.save!
        @players.each { |p| create_player(weekly_team, p) }
        weekly_team
      end
    end

    private

    def build_weekly_team
      WeeklyTeam.new(
        number: @number,
        mode: @mode,
        round_ids: @round_ids,
        team_module_id: @team_module_id,
        season: Season.order(:start_year).last
      )
    end

    def create_player(weekly_team, player_data)
      weekly_team.weekly_team_players.create!(
        slot_id: player_data[:slot_id].to_i,
        round_player_id: player_data[:round_player_id].to_i,
        total: player_data[:total].to_f
      )
    end
  end
end
