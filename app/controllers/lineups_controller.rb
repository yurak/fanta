class LineupsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[details show]

  respond_to :html

  helper_method :team, :lineup, :modules

  def new
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
    redirect_to(teams_path) && return unless lineup_of_team?

    respond_with lineup
  end

  def details
    redirect_to(teams_path) && return unless lineup_of_team?

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
    if duplicate_players&.any?
      flash[:notice] = "Your have same player on multiple positions: #{duplicate_names}"
      redirect_to edit_team_lineup_path(team, lineup)
    else
      flash[:notice] = 'Successfully updated lineup' if lineup.update(update_lineup_params)

      redirect_to team_lineup_path(team, lineup)
    end
  end

  def substitutions
    if score_editable? && lineup.match_players.main.without_score.any?
      respond_with lineup
    else
      flash[:notice] = 'Substitution can not be made'
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

  def lineup_of_team?
    team == lineup.team
  end

  def team_lineups_creator
    @team_lineups_creator ||= TeamLineups::Creator.new(params: lineup_params, team: team)
  end

  def lineup_params
    params.fetch(:lineup, {}).permit(:team_module_id, tema_module_id: [])
  end

  def update_lineup_params
    params.fetch(:lineup, {}).permit(:team_module_id, match_players_attributes: {})
  end

  def duplicate_players
    return unless update_lineup_params[:match_players_attributes]

    player_ids = update_lineup_params[:match_players_attributes].values.each_with_object([]) do |el, player_ids|
      player_ids << el[:player_id]
    end
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
