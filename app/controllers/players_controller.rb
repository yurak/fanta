class PlayersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  helper_method :player, :team

  respond_to :html

  def index
    # TODO: add pagination
    @players = order_players
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

  # TODO: rename to #update
  def change_status
    status = params[:status]

    player.send("#{status}!")
    redirect_to team_path(team)
  end

  private

  def identifier
    params[:player_id].presence || params[:id]
  end

  def team
    @team ||= Team.find(params[:team_id])
  end

  def player
    @player ||= Player.find(identifier)
  end

  def player_params
    params.require(:player).permit(:name, :status)
  end

  def order_players
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
    Player.by_tournament(tournament.id)
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
