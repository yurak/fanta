class MatchPlayersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]

  respond_to :html, :json

  helper_method :tour

  def index
    @players = order_players
    @positions = Position.all
  end

  private

  def identifier
    params[:tour_id].presence || params[:id]
  end

  def tour
    @tour ||= Tour.find(params[:tour_id])
  end

  def tour_players
    tour.match_players.main.with_score
  end

  def order_players
    case stats_params[:order]
    when 'club'
      players_with_filter.sort_by(&:club)
    when 'name'
      players_with_filter.sort_by(&:name)
    when 'base_score'
      players_with_filter.sort_by(&:score).reverse
    when 'total_score'
      players_with_filter.sort_by(&:total_score).reverse
    else
      players_with_filter.sort_by(&:total_score).reverse
    end
  end

  def players_by_position
    tour_players.by_real_position(stats_params[:position]) if stats_params[:position]
  end

  def players_with_filter
    players_by_position || tour_players
  end

  def stats_params
    params.permit(:order, :position)
  end
end
