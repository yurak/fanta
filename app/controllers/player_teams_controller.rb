class PlayerTeamsController < ApplicationController
  respond_to :html

  helper_method :team

  def edit
    redirect_to team_path(team) unless editable?
  end

  def update
    if editable? && valid?
      player_teams.each_pair do |id, params|
        player_team = PlayerTeam.find(id.to_i)
        player_team.update(params.to_hash)
      end
    end

    redirect_to team_path(team)
  end

  private

  def team
    @team ||= Team.find(params[:team_id])
  end

  def editable?
    team.sales_period? && team_of_user?
  end

  def valid?
    return false unless auction

    player_teams.to_h.map { |pt, v| pt if v['transfer_status'] == 'transferable' }.compact.count <= team.available_transfers
  end

  def team_of_user?
    return false unless team.user

    team.user == current_user
  end

  def auction
    @auction ||= team.league.auctions.sales.first
  end

  def player_teams
    @player_teams ||= update_params['player_teams']
  end

  def update_params
    params.permit(player_teams: %i[transfer_status])
  end
end
