class ResultsController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :html

  helper_method :league

  def index
    @results = league.results.ordered
  end

  private

  def league
    @league ||= League.find(params[:league_id])
  end
end
