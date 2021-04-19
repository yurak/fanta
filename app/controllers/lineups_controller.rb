class LineupsController < ApplicationController
  respond_to :html

  helper_method :team, :lineup, :modules, :match_player

  def new
    redirect_to team_path(team) unless team_of_user?

    modules
    @lineup = Lineup.new
  end

  def create
    if team_of_user?
      team_lineups_creator.call

      if team_lineups_creator.lineup.errors.present?
        flash[:error] = "Lineup was not created: #{team_lineups_creator.lineup.errors.full_messages.to_sentence}"
        redirect_to new_team_lineup_path(team)
      else
        redirect_to edit_team_lineup_path(team, team_lineups_creator.lineup)
      end
    else
      redirect_to team_path(team)
    end
  end

  def clone
    team_lineups_cloner.call if team_of_user? && previous_lineup && !tour.lineups.exists?(team_id: previous_lineup.team_id)

    redirect_to tour_path(tour)
  end

  def edit
    redirect_to match_path(lineup.match) unless editable?
  end

  def edit_module
    if editable?
      modules
    else
      redirect_to match_path(lineup.match)
    end
  end

  def update
    if duplicate_players&.any?
      flash[:error] = "ERROR! Same player on multiple positions: #{duplicate_names}"
      redirect_to edit_team_lineup_path(team, lineup)
    else
      if editable?
        recount_round_players_params
        lineup.update(update_lineup_params)
      end

      redirect_to match_path(lineup.match)
    end
  end

  def substitutions
    redirect_to match_path(lineup.match) unless sub_available?
  end

  def subs_update
    if (can? :subs_update, Lineup) && call_substituter
      redirect_to match_path(lineup.match)
    else
      redirect_to substitutions_team_lineup_path(team, lineup)
    end
  end

  private

  def team_lineups_creator
    @team_lineups_creator ||= TeamLineups::Creator.new(params: lineup_params, team: team)
  end

  def team_lineups_cloner
    @team_lineups_cloner ||= TeamLineups::Cloner.new(old_lineup: previous_lineup, tour: tour)
  end

  def previous_lineup
    team.lineups.first if team.lineups.first&.tour&.league == tour.league
  end

  def lineup_params
    params.fetch(:lineup, {}).permit(:team_module_id, tema_module_id: [])
  end

  def update_lineup_params
    params.fetch(:lineup, {}).permit(:team_module_id, match_players_attributes: {})
  end

  def recount_round_players_params
    return unless match_players_attributes

    match_players_attributes.each do |k, _|
      next unless match_players_attributes[k][:round_player_id]

      player = Player.find(match_players_attributes[k][:round_player_id])
      round_player = RoundPlayer.find_or_create_by(tournament_round: tournament_round, player: player)
      match_players_attributes[k][:round_player_id] = round_player.id
    end
  end

  def duplicate_players
    return unless match_players_attributes

    player_ids = match_players_attributes.values.each_with_object([]) { |el, p_ids| p_ids << el[:round_player_id] }
    player_ids.find_all { |id| player_ids.rindex(id) != player_ids.index(id) }
  end

  def match_players_attributes
    update_lineup_params[:match_players_attributes]
  end

  def duplicate_names
    Player.find(duplicate_players.uniq).map(&:name).join(', ')
  end

  def lineup
    @lineup ||= Lineup.find(params[:id])
  end

  def team
    @team ||= Team.find(params[:team_id])
  end

  def tour
    @tour ||= Tour.find(params[:tour_id])
  end

  def tournament_round
    lineup.tour.tournament_round
  end

  def modules
    @modules ||= TeamModule.all
  end

  def match_player
    MatchPlayer.find(params[:mp])
  end

  def team_of_user?
    team.user == current_user
  end

  def editable?
    lineup.tour.set_lineup? && team_of_user?
  end

  def sub_available?
    lineup.tour.locked_or_postponed? && match_player.not_played? && (can? :substitutions, Lineup)
  end

  def call_substituter
    MatchPlayers::Substituter.call(out_mp_id: params[:out_mp_id], in_mp_id: params[:in_mp_id])
  end
end
