class PlayersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  helper_method :player

  respond_to :html

  def index
    @players = Kaminari.paginate_array(ordered_players).page(params[:page])
    @tournaments = Tournament.with_clubs
    @positions = Position.all
    @clubs = tournament.clubs.active.sort_by(&:name)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: player, serializer: PlayerSerializer }
    end
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

  def tournament_players
    Player.by_tournament(tournament)
  end

  def players_by_position
    stats_params[:position] ? tournament_players.by_position(stats_params[:position]) : tournament_players
  end

  def players_with_filter
    stats_params[:club] ? players_by_position.by_club(stats_params[:club]) : players_by_position
  end

  def stats_params
    params.permit(:club, :order, :position, :tournament)
  end

  def tournament
    stats_params[:tournament] ? Tournament.find(stats_params[:tournament]) : Tournament.first
  end
end
