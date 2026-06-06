class RoundPlayersController < ApplicationController
  respond_to :html, :json

  helper_method :tournament_round, :tournament, :deadlined?

  def index
    @players = order_players
    @positions = Position.all
    @clubs = tournament.national? ? tournament.national_teams.active.order(:name) : tournament.clubs.active.order(:name)
    @leagues = tournament.leagues.where(season_id: tournament_round.season_id).viewable.includes(:division).order(:id)
  end

  private

  def deadlined?
    @deadlined ||= tournament_round.tours.last&.deadlined?
  end

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
    apply_order(preloaded_players)
  end

  def preloaded_players
    players = players_with_filter
    return players unless tournament.fanta? && deadlined?

    preload_match_players(players)
  end

  def preload_match_players(players)
    players = players.includes(:club, player: %i[national_team club player_positions positions])
    return players.includes(:match_players) unless selected_league

    players = players.to_a
    ActiveRecord::Associations::Preloader.new.preload(players, :match_players, MatchPlayer.by_league(selected_league.id))
    players
  end

  def selected_league
    return @selected_league if defined?(@selected_league)

    @selected_league = stats_params[:league].present? ? tournament.leagues.find_by(id: stats_params[:league]) : nil
  end

  def apply_order(players)
    case stats_params[:order]
    when 'club'       then sort_by_club(players)
    when 'national'   then players.to_a
    when 'matches'    then sort_by_matches(players)
    when 'main_squad' then sort_by_main_squad(players)
    else                   sort_by_score(players)
    end
  end

  def sort_by_score(players)
    case stats_params[:order]
    when 'name'       then players.sort_by(&:name)
    when 'base_score' then players.sort_by(&:score).reverse
    else                   players.sort_by(&:result_score).reverse
    end
  end

  def sort_by_club(players)
    players.sort_by { |rp| rp.related_club.name }
  end

  def sort_by_matches(players)
    sort_by_appearances(players) { |rp| rp.match_players.size }
  end

  def sort_by_main_squad(players)
    sort_by_appearances(players) { |rp| rp.match_players.select(&:real_position).size }
  end

  def sort_by_appearances(players, &key)
    deadlined? ? players.sort_by(&key).reverse : players.to_a
  end

  def round_players_by_position
    return unless stats_params[:position]

    tour_players.where(player_id: Player.by_position(stats_params[:position]))
  end

  def round_players_by_club
    RoundPlayer.by_club(stats_params[:club]).where(tournament_round: tournament_round) if stats_params[:club]
  end

  def players_with_filter
    round_players_by_position || round_players_by_club || tour_players
  end

  def stats_params
    params.permit(:order, :position, :club, :league, :tournament_round_id)
  end

  def tournament
    @tournament ||= tournament_round.tournament
  end
end
