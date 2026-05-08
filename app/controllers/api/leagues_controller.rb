module Api
  class LeaguesController < Api::ApplicationController
    skip_before_action :authenticate_user!, only: %i[index show]

    respond_to :json

    helper_method :league

    def index
      leagues = filtered_leagues.map { |l| LeagueBaseSerializer.new(l) }

      render json: { data: leagues }
    end

    def show
      if league
        render json: { data: LeagueSerializer.new(league) }
      else
        not_found
      end
    end

    private

    def league
      return @league if defined?(@league)

      @league = League.includes(:division, :season, :tournament, :tours, results: :team).find_by(id: params[:id])
    end

    def filtered_leagues
      League.serial.viewable
            .by_season(filter[:season_id])
            .by_tournament(filter[:tournament_id])
            .without_demo_from_old_seasons
    end

    def filter
      params.fetch(:filter, {}).permit(:season_id, :tournament_id)
    end
  end
end
