class PlayersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  helper_method :league, :player, :tournament

  respond_to :html

  def index
    @players = Kaminari.paginate_array(ordered_players).page(params[:page])
    @tournaments = Tournament.with_clubs
    @positions = Position.all
    @clubs = tournament.clubs.active.sort_by(&:name)

    respond_to do |format|
      format.html
      format.json { render json: ordered_players }
    end
  end

  def show
    @stats = player.player_season_stats.joins(:season, :club, :tournament).order(season_id: :desc, created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: player, serializer: PlayerLineupSerializer }
    end
  end

  def update
    player.teams.each { |team| Transfers::Seller.call(player, team, :left) } if can? :update, Player

    redirect_to player_path(player)
  end

  private

  def player
    @player ||= Player.find(params[:id])
  end

  def ordered_players
    case stats_params[:order]
    when 'club'
      players_with_filter.sort_by(&:club)
    when 'appearances'
      players_with_filter.sort_by(&:season_scores_count).reverse
    when 'rating'
      players_with_filter.sort_by(&:season_average_result_score).reverse
    else
      players_with_filter.sort_by(&:name)
    end
  end

  def players_with_filter
    Players::Search.call(
      club_id: stats_params[:club],
      league_id: stats_params[:league],
      name: stats_params[:search],
      position: Slot::POS_MAPPING[stats_params[:position]],
      tournament_id: stats_params[:tournament]
    )
  end

  def stats_params
    params.permit(:club, :order, :position, :tournament, :search, :league)
  end

  def tournament
    stats_params[:tournament] ? Tournament.find(stats_params[:tournament]) : Tournament.first
  end

  def league
    stats_params[:league] ? League.find(stats_params[:league]) : tournament.leagues.active.first
  end
end
