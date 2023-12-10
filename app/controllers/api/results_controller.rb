module Api
  class ResultsController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index]

    respond_to :json

    def index
      if league
        results = league_results.map { |l| ResultSerializer.new(l) }
        render json: { data: results }
      else
        not_found
      end
    end

    private

    def league
      @league ||= League.find_by(id: params[:league_id])
    end

    def league_results
      @league_results ||= league.results.ordered
    end
  end
end
