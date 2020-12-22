class RoundPlayersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]

  respond_to :html, :json

  helper_method :tournament_round, :tournament

  def index
    @players = order_players
    @positions = Position.all
    @clubs = tournament.clubs.active.sort_by(&:name)
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
    else
      players_with_filter.sort_by(&:result_score).reverse
    end
  end

  def round_players_by_position
    RoundPlayer.where(tournament_round: tournament_round, player_id: player_ids_by_position) if stats_params[:position]
  end

  def player_ids_by_position
    Player.by_position(stats_params[:position]).by_tournament(tournament.id).ids
  end

  def round_players_by_club
    RoundPlayer.by_club(stats_params[:club]).where(tournament_round: tournament_round) if stats_params[:club]
  end

  def players_with_filter
    round_players_by_position || round_players_by_club || tour_players
  end

  def stats_params
    params.permit(:order, :position, :club, :tournament_round_id)
  end

  def tournament
    @tournament ||= tournament_round.tournament
  end
end
