class TeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html, :json

  helper_method :team

  def show
    respond_to do |format|
      format.html
      format.json { render json: team.players.to_json }
    end
  end

  def edit
    redirect_to team_path(team) unless editable?
  end

  def update
    # TODO: compare count of transferable players and count of auction slots
    # player_teams.to_h.map{|pt, v| pt if v["transfer_status"] == "transferable"}.compact.count
    if editable?
      player_teams.each_pair do |id, params|
        player_team = PlayerTeam.find(id.to_i)
        player_team.update(params.to_hash)
      end
    end

    redirect_to team_path(team)
  end

  private

  def team
    @team ||= Team.find(params[:id])
  end

  def editable?
    team.sales_period? && team_of_user?
  end

  def team_of_user?
    return false unless team.user

    team.user == current_user
  end

  def player_teams
    @player_teams ||= update_params['player_teams']
  end

  def update_params
    params.permit(player_teams: %i[transfer_status])
  end
end
