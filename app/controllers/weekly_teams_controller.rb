class WeeklyTeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    @weekly_team = WeeklyTeam.includes(
      :team_module,
      :season,
      weekly_team_players: [
        :slot,
        { round_player: [{ tournament_round: :tournament }, { player: %i[positions national_team] }, { club: :tournament }] }
      ]
    ).find(params[:id])

    @season_bonuses = build_season_bonuses if @weekly_team.source_avg?
  end

  private

  def build_season_bonuses
    player_ids = @weekly_team.weekly_team_players.map { |wtp| wtp.round_player.player_id }
    round_ids  = TournamentRound.by_tournament(@weekly_team.tournament_id)
                                .by_season(@weekly_team.season_id)
                                .pluck(:id)

    RoundPlayer.where(tournament_round_id: round_ids, player_id: player_ids)
               .where('score > 0')
               .includes(:player)
               .group_by(&:player_id)
               .transform_values { |rps| WeeklyTeams::SeasonBonuses.from_round_players(rps) }
  end
end
