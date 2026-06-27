class NationalTeamsController < ApplicationController
  respond_to :html

  helper_method :national_team, :national_teams, :league

  def show; end

  private

  def national_team
    @national_team ||= NationalTeam.includes(:tournament, players: %i[club positions]).find(params.expect(:id))
  end

  def national_teams
    @national_teams ||= NationalTeam.where(tournament_id: national_team.tournament_id).active.order(:name)
  end

  def league
    @league ||= current_user&.league_by_tournament(national_team.tournament_id)
  end
end
