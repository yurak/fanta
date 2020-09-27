class LineupsController < ApplicationController
  respond_to :html

  helper_method :team, :lineup, :modules

  def new
    modules
    @lineup = Lineup.new
  end

  def create
    team_lineups_creator.call

    if team_lineups_creator.lineup.errors.present?
      flash[:error] = "Lineup was not created: #{team_lineups_creator.lineup.errors.full_messages.to_sentence}"
      redirect_to new_team_lineup_path(team)
    else
      flash[:notice] = 'Successfully created lineup'
      redirect_to edit_team_lineup_path(team, team_lineups_creator.lineup)
    end
  end

  def clone
    if previous_lineup
      if tour.lineups.where(team_id: previous_lineup.team_id).exists?
        flash[:error] = 'This team already has lineup for tour'
      else
        team_lineups_cloner.call
      end
    end

    redirect_to tour_path(tour)
  end

  def edit
    if editable?
      respond_with lineup
    else
      flash[:notice] = 'This lineup can not be edited'
      redirect_to match_path(lineup.match)
    end
  end

  def edit_module
    if editable?
      modules
      respond_with lineup
    else
      flash[:notice] = 'This lineup can not be edited'
      redirect_to match_path(lineup.match)
    end
  end

  def edit_scores
    if score_editable?
      respond_with lineup
    else
      flash[:notice] = 'This lineup can not be edited'
      redirect_to match_path(lineup.match)
    end
  end

  def update
    if duplicate_players&.any?
      flash[:error] = "ERROR! Same player on multiple positions: #{duplicate_names}"
      redirect_to edit_team_lineup_path(team, lineup)
    else
      recount_round_players_params
      flash[:notice] = 'Successfully updated lineup' if lineup.update(update_lineup_params)

      redirect_to match_path(lineup.match)
    end
  end

  def substitutions
    if score_editable? && lineup.match_players.main.without_score.any?
      respond_with lineup
    else
      flash[:notice] = 'Substitution can not be made'
      redirect_to match_path(lineup.match)
    end
  end

  def subs_update
    # TODO: move action to Substitution service
    substitution_params

    if (@mp_main.available_positions & @mp_reserve.player.position_names).any?
      MatchPlayer.transaction do
        new_round_player = @mp_reserve.round_player
        @mp_reserve.update(round_player_id: @mp_main.round_player_id, subs_status: :get_out, cleansheet: false, position_malus: 0)
        @mp_main.update(round_player_id: new_round_player.id, subs_status: :get_in, cleansheet: false, position_malus: 0)
      end
      flash[:notice] = 'Successfully made substitution'
      redirect_to match_path(lineup.match)
    else
      flash[:error] = "#{@mp_reserve.player.name} can not take position #{@mp_main.real_position}"
      redirect_to team_lineup_substitutions_path(team, lineup)
    end
  end

  private

  def lineup_of_team?
    team == lineup.team
  end

  def team_lineups_creator
    @team_lineups_creator ||= TeamLineups::Creator.new(params: lineup_params, team: team)
  end

  def team_lineups_cloner
    @team_lineups_cloner ||= TeamLineups::Cloner.new(old_lineup: previous_lineup, tour: tour)
  end

  def previous_lineup
    return unless team.lineups.first.tour.league == tour.league

    team.lineups.first
  end

  def lineup_params
    params.fetch(:lineup, {}).permit(:team_module_id, tema_module_id: [])
  end

  def update_lineup_params
    params.fetch(:lineup, {}).permit(:team_module_id, match_players_attributes: {})
  end

  def recount_round_players_params
    return unless params[:lineup][:match_players_attributes]

    params[:lineup][:match_players_attributes].each do |k, _|
      next unless params[:lineup][:match_players_attributes][k][:round_player_id]

      player = Player.find(params[:lineup][:match_players_attributes][k][:round_player_id])
      round_player = RoundPlayer.find_or_create_by(tournament_round: tournament_round, player: player)
      params[:lineup][:match_players_attributes][k][:round_player_id] = round_player.id
    end
  end

  def duplicate_players
    return unless update_lineup_params[:match_players_attributes]

    player_ids = update_lineup_params[:match_players_attributes].values.each_with_object([]) { |el, p_ids| p_ids << el[:round_player_id] }
    player_ids.find_all { |id| player_ids.rindex(id) != player_ids.index(id) }
  end

  def duplicate_names
    Player.find(duplicate_players.uniq).map(&:name).join(', ')
  end

  def substitution_params
    @mp_main = MatchPlayer.find(params[:out_mp_id])
    @mp_reserve = MatchPlayer.find(params[:in_mp_id])
  end

  def lineup
    @lineup ||= Lineup.find(identifier)
  end

  def identifier
    params[:id] || params[:lineup_id]
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

  def editable?
    lineup.tour.set_lineup? && current_user == lineup.team.user
  end

  def score_editable?
    lineup.tour.locked_or_postponed? && (current_user&.admin? || current_user&.moderator?)
  end
end
