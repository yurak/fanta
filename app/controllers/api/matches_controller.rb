module Api
  class MatchesController < ActionController::API
    def results
      matches = Tour.closed.last.matches
      render json: matches, each_serializer: MatchSerializer
    end

    def fixtures
      matches = Tour.active.matches
      render json: matches, each_serializer: MatchSerializer
    end
  end
end
