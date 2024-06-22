class RoundPlayersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]

  respond_to :html, :json

  helper_method :tournament_round, :tournament

  def index
    @players = order_players
    @positions = Position.all
    @clubs = tournament.national? ? tournament.national_teams.active.sort_by(&:name) : tournament.clubs.active.sort_by(&:name)
  end

  private

  def tournament_round
    @tournament_round ||= TournamentRound.find(params[:tournament_round_id])
  end

  def tour_players
    if tournament.national?
      tournament_round.round_players
    elsif tournament.eurocup?
      tournament_round.eurocup_players
    else
      tournament_round.round_players.with_score
    end
  end

  def order_players
    case stats_params[:order]
    when 'club'
      players_with_filter.sort_by(&:club)
    when 'national'
      players_with_filter
    when 'matches'
      tournament_round.tours.last&.deadlined? ? players_with_filter.sort_by(&:appearances).reverse : players_with_filter
    when 'main_squad'
      tournament_round.tours.last&.deadlined? ? players_with_filter.sort_by(&:main_appearances).reverse : players_with_filter
    when 'name'
      players_with_filter.sort_by(&:name)
    when 'base_score'
      players_with_filter.sort_by(&:score).reverse
    else
      players_with_filter.sort_by(&:result_score).reverse
    end
  end

  def round_players_by_position
    return unless stats_params[:position]

    if tournament.eurocup?
      tour_players.where(player_id: player_ids_by_position)
    else
      tournament_round.round_players.where(player_id: player_ids_by_position)
    end
  end

  def player_ids_by_position
    if tournament.national?
      Player.by_position(stats_params[:position]).by_national_tournament(tournament.id).ids
    elsif tournament.eurocup?
      Player.by_position(stats_params[:position]).by_ec_tournament(tournament).ids
    else
      Player.by_position(stats_params[:position]).by_tournament(tournament).ids
    end
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
