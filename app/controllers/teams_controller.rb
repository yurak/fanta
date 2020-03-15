class TeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  respond_to :html

  helper_method :team, :league

  def index
    # TODO: stats page temporary disabled
    # @players = order_players
    # @teams = league.teams
    # @positions = Position.all
    # @tours = Tour.closed
    # @tour_players = tour_players
  end

  private

  def team
    @team ||= Team.find(params[:id])
  end

  def league
    @league ||= League.find(params[:league_id])
  end

  # def order_players
  #   case stats_params[:order]
  #   when 'club'
  #     players_stats.sort_by(&:club)
  #   when 'name'
  #     players_stats.sort_by(&:name)
  #   when 'team'
  #     players_stats.sort_by { |p| p.team&.id.to_i }
  #   when 'mp'
  #     players_stats.sort_by(&:played_matches_count).reverse
  #   when 'sc'
  #     players_stats.sort_by(&:scores_count).reverse
  #   when 'avbs'
  #     players_stats.sort_by(&:average_score).reverse
  #   else
  #     players_stats.sort_by(&:average_total_score).reverse
  #   end
  # end

  # def league_players
  #   @league_players ||= Player.all.where(team_id: league.teams.ids)
  # end

  # def players_stats
  #   players = players_with_filter || league_players
  #   players.stats_query
  # end

  # def players_with_filter
  #   team_filter&.players || players_by_position
  # end

  # def team_filter
  #   Team.find(stats_params[:team]) if stats_params[:team]
  # end

  # def players_by_position
  #   league_players.by_position(stats_params[:position]) if stats_params[:position]
  # end

  # def stats_params
  #   params.permit(:order, :team, :position, :tour)
  # end

  # def tour_players
  #   tour = club_params[:tour] ? Tour.find(club_params[:tour]) : Tour.closed.last
  #   tour.match_players.main.with_score.sort_by(&:total_score).reverse
  # end
end
