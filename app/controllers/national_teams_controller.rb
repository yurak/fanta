class NationalTeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html

  helper_method :national_team, :national_teams

  def show; end

  private

  def national_team
    @national_team ||= NationalTeam.find(params[:id])
  end

  def national_teams
    @national_teams ||= national_team.tournament.national_teams.active.order(:name)
  end
end
