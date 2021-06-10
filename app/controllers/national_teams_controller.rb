class NationalTeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html

  helper_method :national_team

  def show; end

  private

  def national_team
    @national_team ||= NationalTeam.find(params[:id])
  end
end
