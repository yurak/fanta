class ResultsController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :html

  helper_method :league

  def index
    @results = Result.by_league(params[:league_id]).ordered

    respond_with @results
  end

  private

  def league
    @league ||= League.find(params[:league_id])
  end
end
