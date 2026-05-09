class NationalTeamsController < ApplicationController
  respond_to :html

  helper_method :national_team, :national_teams

  def show; end

  private

  def national_team
    @national_team ||= NationalTeam.includes(players: [:club, :positions]).find(params[:id])
  end

  def national_teams
    @national_teams ||= national_team.tournament.national_teams.active.order(:name)
  end
end
