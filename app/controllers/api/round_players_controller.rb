module Api
  class RoundPlayersController < Api::ApplicationController
    skip_before_action :authenticate_user!, only: %i[index meta]

    respond_to :json

    def index
      result = RoundPlayers::Query.call(query_params)
      players = paginate(result)
      players_ser = players.map { |rp| serialize(rp) }
      render json: { data: players_ser, meta: response_options(players) }
    end

    # Who fielded this player in their starting eleven this round -- the teams the "in the eleven"
    # count on the row adds up to. Fanta only in practice: in mantra a player belongs to one team,
    # and the row already names it.
    def teams
      round_player = tournament_round.round_players.find(params.expect(:id))

      render json: { data: fielding_teams(round_player) }
    end

    def meta
      render json: { data: {
        tournament_name: tournament.name,
        number: tournament_round.number,
        national: tournament.national?,
        fanta: tournament.fanta?,
        deadlined: deadlined?,
        leagues: leagues_payload,
        clubs: clubs_payload
      } }
    end

    private

    def serialize(round_player)
      RoundPlayerStatsSerializer.new(
        round_player,
        league_id: filter_params[:league_id],
        national: tournament.national?,
        fanta: tournament.fanta?,
        mantra: tournament.mantra?,
        deadlined: deadlined?,
        my_picks: my_picks
      )
    end

    def my_picks
      return @my_picks if defined?(@my_picks)
      return @my_picks = {} unless current_user && filter_params[:league_id]

      @my_picks = picks_from(my_lineup)
    end

    def my_lineup
      Lineup.joins(:tour, :team).find_by(
        teams: { user_id: current_user.id },
        tours: { tournament_round_id: tournament_round.id, league_id: filter_params[:league_id] }
      )
    end

    def picks_from(lineup)
      return {} unless lineup

      lineup.match_players.where.not(subs_status: :not_in_squad)
            .to_h { |mp| [mp.round_player_id, mp.real_position.present? ? 'main' : 'bench'] }
    end

    def query_params
      filter_params.merge(order_params).merge(tournament_round_id: params[:tournament_round_id])
    end

    def filter_params
      params.fetch(:filter, {}).permit(:league_id, :name, club_id: [], position: [])
    end

    def order_params
      params.fetch(:order, {}).permit(:direction, :field)
    end

    def fielding_teams(round_player)
      MatchPlayer.where(round_player_id: round_player.id).where.not(real_position: nil)
                 .includes(lineup: :team)
                 .filter_map { |match_player| team_entry(match_player.lineup&.team) }
                 .sort_by { |entry| entry[:name].to_s.downcase }
    end

    def team_entry(team)
      return unless team

      { id: team.id, name: team.human_name, logo_path: team.logo_path }
    end

    def leagues_payload
      tournament.leagues
                .where(season_id: tournament_round.season_id)
                .viewable.includes(:division).order(:id)
                .map { |league| { id: league.id, name: league.division_with_name } }
    end

    # The clubs (or, on national rounds, national teams) actually present in
    # this round, for the club filter dropdown.
    def clubs_payload
      if tournament.national?
        NationalTeam.where(id: round_national_team_ids).order(:name)
                    .map { |team| { id: team.id, name: team.name, logo_path: nil, flag_code: team.code } }
      else
        Club.where(id: round_club_ids).order(:name)
            .map { |club| { id: club.id, name: club.name, logo_path: club.logo_path, flag_code: nil } }
      end
    end

    # Same base scope the list uses, so the dropdown matches the visible rows
    # (e.g. eurocup rounds -> participating ec_clubs only).
    def base_round_players
      @base_round_players ||= RoundPlayers::Query.base_scope_for(tournament_round)
    end

    def round_club_ids
      base_round_players.joins(:player)
                        .pluck(Arel.sql('COALESCE(round_players.club_id, players.club_id)')).uniq.compact
    end

    def round_national_team_ids
      Player.where(id: base_round_players.select(:player_id))
            .where.not(national_team_id: nil).distinct.pluck(:national_team_id)
    end

    def deadlined?
      @deadlined ||= tournament_round.tours.last&.deadlined?
    end

    def tournament_round
      @tournament_round ||= TournamentRound.find(params.expect(:tournament_round_id))
    end

    def tournament
      @tournament ||= tournament_round.tournament
    end
  end
end
