class WeeklyTeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    @weekly_team = WeeklyTeam.includes(
      :team_module,
      :season,
      weekly_team_players: [
        :slot,
        { player: [:positions, :national_team, { club: :tournament }] },
        { round_player: [
          { tournament_round: { tournament: :national_teams } },
          { player: %i[positions national_team] },
          { club: :tournament }
        ] }
      ]
    ).find(params.expect(:id))

    @season_bonuses    = build_season_bonuses if @weekly_team.source_avg?
    @round_top_lineups = round_top_lineups if @weekly_team.source_round? && @weekly_team.top?
  end

  private

  def round_top_lineups
    rounds = TournamentRound.where(id: @weekly_team.round_ids).includes(:tournament).index_by(&:id)

    @weekly_team.round_ids.filter_map { |round_id| rounds[round_id] }
                          .map { |round| [round, top_lineup_for(round)] }
  end

  def top_lineup_for(round)
    Lineup.joins(:tour)
          .where(tours: { tournament_round_id: round.id })
          .includes(team: :user)
          .order(final_score: :desc)
          .first
  end

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
