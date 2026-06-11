module Manage
  class PlayersController < BaseController
    def index
      @players = filter_players.order(id: :desc).page(params[:page]).per(PER_PAGE)
      @clubs = Club.active.order(:name)
    end

    def show
      @player = Player.includes(:club, :positions, :national_team,
                                club_transfers: %i[old_club new_club]).find(params[:id])
      @club_transfers = @player.club_transfers.recent
      @active_clubs = Club.active.order(:name)
      @teams = @player.teams.includes(league: :tournament)
      @team_transfers = @player.transfers.incoming.index_by(&:team_id)
      @season_stats = player_season_stats
    end

    def create
      result = parse_player_hash(params[:player_hash])

      if result.nil?
        redirect_to manage_players_path, alert: t('manage.players.invalid_hash')
        return
      end

      if Players::Manager.call(result)
        redirect_to manage_players_path, notice: t('manage.players.created')
      else
        redirect_to manage_players_path, alert: t('manage.players.failed')
      end
    end

    private

    def player_season_stats
      PlayerSeasonStat.includes(:club, :season)
                      .where(player: @player)
                      .order('seasons.start_year DESC')
                      .references(:season)
    end

    def filter_players
      players = Player.includes(:club, :positions)
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

    def parse_player_hash(raw)
      return nil if raw.blank?

      json_str = raw.strip.gsub('=>', ':').gsub(/\bnil\b/, 'null')
      JSON.parse(json_str)
    rescue JSON::ParserError
      nil
    end
  end
end
