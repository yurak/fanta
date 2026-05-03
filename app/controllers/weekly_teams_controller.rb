class WeeklyTeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    @weekly_team = WeeklyTeam.includes(
      :team_module,
      :season,
      weekly_team_players: [
        :slot,
        { round_player: [{ player: :positions }, { club: :tournament }] }
      ]
    ).find(params[:id])
  end
end
