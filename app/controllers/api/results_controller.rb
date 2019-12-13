module Api
  class ResultsController < ActionController::API
    def index
      results = Result.all.order(points: :desc).order(Arel.sql("scored_goals - missed_goals desc")).order(scored_goals: :desc)
      render json: results, each_serializer: ResultSerializer
    end

    def show
      matches = tour.matches
      render json: matches, each_serializer: MatchSerializer
    end

    private

    def tour
      Tour.find(params[:id]) || Tour.closed.last
    end
  end
end
