class LineupsController < ApplicationController
  before_action :modules, only: %i[new edit]

  respond_to :html

  helper_method :lineup, :match_player, :modules, :team, :team_module, :tour

  def show
    preload_round_matches
  end

  def new
    redirect_to tour_path(tour) unless valid_conditions?

    @lineup = Lineup.new(team_module: team_module, tour: tour, team: team)
    build_match_players
  end

  def edit
    team_module
    preload_round_matches

    redirect_to tour_path(tour) unless editable?
  end

  def create
    path = tour_path(tour)

    if valid_conditions?
      if invalid_players?(Lineup.new(team_module: team_module, tour: tour, team: team).players_count)
        flash[:alert] = t('lineups.invalid_squad')
        path = new_team_lineup_path(team, team_module_id: params.dig(:lineup, :team_module_id), tour_id: tour.id)
      else
        recount_round_players_params
        @lineup = Lineup.new(lineup_params.merge(team: team))
        path = saved_lineup_path
      end
    end

    redirect_to path
  end

  def update
    return redirect_to(saved_or_tour_path) unless editable?

    if invalid_players?(lineup.players_count)
      flash[:alert] = t('lineups.invalid_squad')
      redirect_to edit_team_lineup_path(team, lineup)
    else
      recount_round_players_params
      lineup.update(update_lineup_params.merge(last_edited_at: Time.current))
      redirect_to saved_or_tour_path
    end
  end

  def clone
    team_lineups_cloner.call if team_of_user?

    redirect_to tour_path(tour)
  end

  def fanta_copy
    Lineups::FantaCopier.call(lineup) if team_of_user?

    redirect_to team_lineup_path(team, lineup)
  end

  private

  def saved_lineup_path
    return new_team_lineup_path(team, team_module_id: @lineup.team_module_id, tour_id: @lineup.tour_id) unless @lineup.save

    tour.fanta? ? team_lineup_path(team, @lineup) : tour_path(tour)
  end

  def saved_or_tour_path
    tour.fanta? ? team_lineup_path(team, lineup) : tour_path(tour)
  end

  def team_lineups_cloner
    @team_lineups_cloner ||= Lineups::Cloner.new(team, tour)
  end

  def lineup_params
    params.expect(lineup: [:team_module_id, :tour_id, { match_players_attributes: {} }])
  end

  def update_lineup_params
    params.expect(lineup: [:team_module_id, { match_players_attributes: {} }])
  end

  def build_match_players
    @lineup.players_count.times { @lineup.match_players.build }
  end

  def recount_round_players_params
    match_players = params.dig(:lineup, :match_players_attributes)
    return if match_players.blank?

    match_players.each_value do |attrs|
      next if attrs[:round_player_id].blank?

      player = Player.find(attrs[:round_player_id])

      round_player = RoundPlayer.find_or_create_by(tournament_round: tour.tournament_round, player: player)
      round_player.update(club: player.club) if round_player.club_id != player.club_id
      attrs[:round_player_id] = round_player.id
    end
  end

  def lineup
    return @lineup if defined?(@lineup)

    @lineup = Lineup.includes(*lineup_includes).find_by(id: params[:id])
  end

  def lineup_includes
    player = [:national_team, :positions, { club: :tournament }]
    round_player = [:club, :tournament_round, { player: player }]
    [
      { tour: :tournament_round },
      { team: [:user, { league: :tournament }] },
      { team_module: :slots },
      { match_players: [:main_subs, { round_player: round_player }] }
    ]
  end

  def preload_round_matches
    return unless lineup

    t_rounds = (
      lineup.match_players.filter_map { |mp| mp.round_player&.tournament_round } +
      [lineup.tour&.tournament_round]
    ).compact.uniq(&:id)
    return if t_rounds.empty?

    ActiveRecord::Associations::Preloader.new(
      records: t_rounds,
      associations: [{ tournament_matches: %i[host_club guest_club] }, { national_matches: %i[host_team guest_team] }]
    ).call
  end

  def team
    @team ||= Team.find(params.expect(:team_id))
  end

  def team_module
    @team_module ||= TeamModule.find_by(id: params[:team_module_id]) || TeamModule.first
  end

  def tour
    @tour ||= lineup&.tour ||
      Tour.includes(tournament_round: { national_matches: %i[host_team guest_team] }).find(params[:tour_id] ||
      lineup_params[:tour_id])
  end

  def modules
    @modules ||= TeamModule.all
  end

  def team_of_user?
    return false unless team.user

    team.user == current_user
  end

  def valid_conditions?
    team_of_user? && tour.set_lineup? && !tour_lineup_exist?
  end

  def players_ids
    match_players = params.dig(:lineup, :match_players_attributes)
    return if match_players.blank?

    match_players.values.each_with_object([]) { |el, p_ids| p_ids << el[:round_player_id] }
  end

  def invalid_players?(required_count)
    return true if duplicate_players&.any? || players_incomplete?(required_count) || players_outside_pool?

    invalid_players_count?
  end

  def players_incomplete?(required_count)
    ids = players_ids
    return true if ids.blank? || ids.size != required_count || ids.any?(&:blank?)

    Player.where(id: ids).distinct.count != ids.uniq.size
  end

  def players_outside_pool?
    ids = players_ids.map(&:to_i).uniq

    pool_scope.where(id: ids).distinct.count != ids.size
  end

  def pool_scope
    return team.players unless tour.fanta?

    round = tour.tournament_round
    round.national_matches.exists? ? Player.by_national_tournament_round(round) : Player.by_tournament_round(round)
  end

  def invalid_players_count?
    return false unless tour.national?

    national_team_ids = Player.find(players_ids).map(&:national_team_id)
    return true if national_team_ids.uniq.count < tour.national_teams_count

    national_teams_hash = national_team_ids.each_with_object(Hash.new(0)) { |word, counts| counts[word] += 1 }
    return true if national_teams_hash.values.max > tour.max_country_players

    false
  end

  def duplicate_players
    players_ids&.find_all { |id| players_ids.rindex(id) != players_ids.index(id) }
  end

  def tour_lineup_exist?
    tour.lineups.find_by(team: team)
  end

  def editable?
    tour.set_lineup? && team_of_user?
  end
end
