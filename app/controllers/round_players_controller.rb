class RoundPlayersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]

  respond_to :html, :json

  helper_method :tournament_round

  def index
    @players = order_players
    @positions = Position.all
  end

  private

  def identifier
    params[:tournament_round_id].presence || params[:id]
  end

  def tournament_round
    @tournament_round ||= TournamentRound.find(params[:tournament_round_id])
  end

  def tour_players
    tournament_round.round_players.with_score
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
      players_with_filter.sort_by(&:result_score).reverse
    else
      players_with_filter.sort_by(&:result_score).reverse
    end
  end

  def players_by_position
    RoundPlayer.where(tournament_round: tournament_round, player_id: player_ids) if stats_params[:position]
  end

  def player_ids
    Player.by_position(stats_params[:position]).by_tournament(tournament.id).ids
  end

  def players_with_filter
    players_by_position || tour_players
  end

  def stats_params
    params.permit(:order, :position)
  end

  def tournament
    @tournament ||= tournament_round.tournament
  end
end
