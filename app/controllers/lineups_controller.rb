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

  def show
    respond_with lineup
  end

  def details
    respond_with lineup
  end

  def clone
    new_lineup = lineup.dup
    new_lineup.tour = Tour.find_by(number: lineup.tour.next_number)

    if new_lineup.tour.lineups.where(team_id: new_lineup.team_id).exists?
      flash[:error] = 'This team already has lineup for tour'
    else
      new_lineup.players << lineup.players.limit(Lineup::MAX_PLAYERS)

      flash[:notice] = 'Successfully updated lineup' if new_lineup.save
    end

    redirect_to team_path(team)
  end

  def edit
    if editable?
      respond_with lineup
    else
      flash[:notice] = 'This lineup can not be edited'
      redirect_to team_lineup_path(team, lineup)
    end
  end

  def edit_module
    if editable?
      modules
      respond_with lineup
    else
      flash[:notice] = 'This lineup can not be edited'
      redirect_to team_lineup_path(team, lineup)
    end
  end

  def edit_scores
    if score_editable?
      respond_with lineup
    else
      flash[:notice] = 'This lineup can not be edited'
      redirect_to team_lineup_path(team, lineup)
    end
  end

  def update
    flash[:notice] = 'Successfully updated lineup' if lineup.update(update_lineup_params)

    redirect_to team_lineup_path(team, lineup)
  end

  def substitutions
    if score_editable?
      respond_with lineup
    else
      flash[:notice] = 'This lineup can not be edited'
      redirect_to team_lineup_path(team, lineup)
    end
  end

  def subs_update
    substitution_params
    if (@mp_main.available_positions & @mp_reserve.player.position_names).any?
      MatchPlayer.transaction do
        new_player = @mp_reserve.player
        @mp_reserve.update(player_id: @mp_main.player_id, subs_status: :get_out)
        @mp_main.update(player_id: new_player.id, subs_status: :get_in)
      end
      flash[:notice] = 'Successfully made substitution'
      redirect_to team_lineup_edit_scores_path(team, lineup)
    else
      flash[:error] = "#{@mp_reserve.player.name} can not take position #{@mp_main.real_position}"
      redirect_to team_lineup_substitutions_path(team, lineup)
    end
  end

  private

  def team_lineups_creator
    @team_lineups_creator ||= TeamLineups::Creator.new(params: lineup_params, team: team)
  end

  def lineup_params
    params.fetch(:lineup, {}).permit(:team_module_id, tema_module_id: [])
  end

  def update_lineup_params
    params.fetch(:lineup, {}).permit(:team_module_id, match_players_attributes: {})
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

  def modules
    @modules ||= TeamModule.all
  end

  def editable?
    lineup.tour.set_lineup? && current_user == lineup.team.user
  end

  def score_editable?
    lineup.tour.locked? && (current_user.admin? || current_user.moderator?)
  end
end
