class ClubsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  respond_to :html

  def index
    # TODO: move to LeagueController
    @players = order_players
    @teams = Team.all
    @positions = Position.all
    @clubs = Club.all.order_by_players_count
    @tours = Tour.closed
    @tour_players = tour_players
  end

  private

  def order_players
    case club_params[:order]
    when 'club'
      all_players.sort_by(&:club)
    when 'team'
      all_players.sort_by { |p| p.team&.id.to_i }
    when 'mp'
      all_players.sort_by(&:played_matches_count).reverse
    when 'sc'
      all_players.sort_by(&:scores_count).reverse
    when 'avbs'
      all_players.sort_by(&:average_score).reverse
    else
      all_players.sort_by(&:average_total_score).reverse
    end
  end

  def all_players
    filter ? filter.players.stats_query : Player.all.stats_query
  end

  def filter
    team || position
  end

  def team
    Team.find(club_params[:team]) if club_params[:team]
  end

  def position
    Position.find(club_params[:position]) if club_params[:position]
  end

  def tour_players
    tour = club_params[:tour] ? Tour.find(club_params[:tour]) : Tour.closed.last
    tour.match_players.main.with_score.sort_by(&:total_score).reverse
  end

  def club_params
    params.permit(:order, :team, :position, :tour)
  end
end
