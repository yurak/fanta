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

    def meta
      render json: { data: {
        tournament_name: tournament.name,
        number: tournament_round.number,
        national: tournament.national?,
        fanta: tournament.fanta?,
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
        deadlined: deadlined?
      )
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
      @tournament_round ||= TournamentRound.find(params[:tournament_round_id])
    end

    def tournament
      @tournament ||= tournament_round.tournament
    end
  end
end
