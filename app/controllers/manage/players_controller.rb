module Manage
  class PlayersController < BaseController
    def index
      @players = filter_players.order(id: :desc).page(params[:page]).per(PER_PAGE)
      @clubs = Club.active.order(:name)
    end

    def show
      @player = Player.includes(:club, :positions, :national_team,
                                club_transfers: %i[old_club new_club]).find(params.expect(:id))
      @club_transfers = @player.club_transfers.recent
      @teams = @player.teams.includes(league: :tournament)
      @team_transfers = @player.transfers.incoming.index_by(&:team_id)
      @season_stats = player_season_stats
      @round_players = current_season_round_players
    end

    def edit
      @player = Player.find(params.expect(:id))
    end

    def create
      data = Players::Transfermarkt::ApiParser.call(params[:tm_id].to_s.strip.presence)

      if data && Players::Manager.call(data.stringify_keys)
        redirect_to manage_players_path, notice: t('manage.players.created')
      else
        redirect_to manage_players_path, alert: t('manage.players.failed')
      end
    rescue Players::Transfermarkt::ApiError => e
      redirect_to manage_players_path, alert: t('manage.players.tm_unavailable', error: e.http_code || e.message)
    end

    def update
      @player = Player.find(params.expect(:id))

      if @player.update(player_params)
        redirect_to manage_player_path(@player), notice: t('manage.players.updated')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def fotmob_search
      @player = Player.find(params.expect(:id))
      @candidates = Players::Fotmob::IdFinder.call(@player.full_name)
    end

    def update_fotmob
      player = Player.find(params.expect(:id))

      if player.update(fotmob_id: params[:fotmob_id])
        redirect_to manage_player_path(player), notice: t('manage.players.fotmob_saved')
      else
        redirect_to fotmob_search_manage_player_path(player), alert: t('manage.players.fotmob_failed')
      end
    end

    private

    def player_params
      params.expect(player: %i[first_name name tm_id fotmob_id sofascore_id avatar_name height number birth_date])
    end

    def player_season_stats
      PlayerSeasonStat.includes(:club, :season)
                      .where(player: @player)
                      .order('seasons.start_year DESC')
                      .references(:season)
    end

    def current_season_round_players
      RoundPlayer.where(player: @player)
                 .includes(:club, tournament_round: :tournament)
                 .references(:tournament_round)
                 .where(tournament_rounds: { season_id: Season.last&.id })
                 .order('tournament_rounds.number DESC')
    end

    def filter_players
      players = Player.includes(:positions, club: :tournament)
      if params[:name].present?
        players = players.where('players.name ILIKE ? OR players.first_name ILIKE ?',
                                "%#{params[:name]}%", "%#{params[:name]}%")
      end
      players = players.where(id: params[:id]) if params[:id].present?
      players = players.where(tm_id: params[:tm_id]) if params[:tm_id].present?
      players = players.where(fotmob_id: params[:fotmob_id]) if params[:fotmob_id].present?
      players = players.joins(:club).where(clubs: { id: params[:club_id] }) if params[:club_id].present?
      players
    end
  end
end
