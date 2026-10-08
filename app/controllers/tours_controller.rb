class ToursController < ApplicationController
  respond_to :html, :json

  helper_method :tour

  def show
    if tour
      preload_tour_matches(tour)
      @results_ordered = tour.league.results.includes(:team).ordered.to_a
      @results_by_score = tour.league.results.includes(:team).ordered_by_score.limit(5)
      @matches = tour.tournament_round.ordered_tournament_matches
    else
      redirect_to leagues_path
    end
  end

  def tournament_players
    if tour
      @tournament_players = tour.round_players.with_score
                                .includes(:club, :tournament_round, player: %i[positions club national_team])
                                .sort_by { |rp| -rp.result_score }.take(5)

      @teams_by_player = teams_by_round_player(@tournament_players.map(&:id))

      respond_to do |format|
        format.html { render partial: 'tours/tournament_players', layout: false }
      end
    else
      redirect_to leagues_path
    end
  end

  def league_players
    if tour
      @league_players = MatchPlayer.by_tour(tour.id).main_with_score
                                   .includes(round_player: [:club, :tournament_round, { player: %i[positions club] }],
                                             lineup: :team)
                                   .sort_by { |mp| -mp.total_score }.take(5)

      @teams_by_player = @league_players.to_h { |mp| [mp.id, mp.team] }

      respond_to do |format|
        format.html { render partial: 'tours/league_players', layout: false }
      end
    else
      redirect_to leagues_path
    end
  end

  def update
    tour_manager.call if can? :update, Tour

    redirect_to tour_path(tour)
  end

  # TODO: move action to TournamentRoundController#inject_scores or RoundPlayersController#update
  def inject_scores
    if can? :inject_scores, Tour
      injector = "Scores::Injectors::#{tournament_round.tournament.source.capitalize}".constantize
      injector.call(tournament_round)
      tournament_round.tours.each do |tour|
        Scores::PositionMalus::Updater.call(tour)
        Lineups::Updater.call(tour)
      end
    end

    path = params['redirect'] == 'round' ? tournament_round_path(tournament_round) : tour_path(tour)
    redirect_to path
  end

  private

  def teams_by_round_player(round_player_ids)
    MatchPlayer.by_tour(tour.id).where(round_player_id: round_player_ids)
               .includes(lineup: :team)
               .to_h { |match_player| [match_player.round_player_id, match_player.team] }
  end

  def tour
    return @tour if defined?(@tour)

    @tour = Tour.includes(
      tournament_round: [
        :tournament,
        { tournament_matches: %i[host_club guest_club] },
        { national_matches: %i[host_team guest_team] }
      ],
      league: :tours
    ).find_by(id: params[:id])
  end

  def preload_tour_matches(tour)
    ActiveRecord::Associations::Preloader.new(records: [tour], associations: { matches: { host: :user, guest: :user } }).call
    ActiveRecord::Associations::Preloader.new(records: [tour], associations: { lineups: :team }).call

    all_team_ids = tour.matches.flat_map { |m| [m.host_id, m.guest_id] }.uniq
    lineups = Lineup.includes(:tour).where(tour_id: tour.id, team_id: all_team_ids).index_by(&:team_id)

    tour.matches.each do |m|
      m.define_singleton_method(:host_lineup) { lineups[host_id] }
      m.define_singleton_method(:guest_lineup) { lineups[guest_id] }
    end
  end

  def tournament_round
    @tournament_round ||= tour.tournament_round
  end

  def tour_manager
    @tour_manager ||= Tours::Manager.new(tour, params[:status])
  end
end
