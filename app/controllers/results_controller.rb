class ResultsController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :html

  def index
    @results = Result.all.order(points: :desc).order(Arel.sql("scored_goals - missed_goals desc")).order(scored_goals: :desc)

    respond_with @results
  end
end
