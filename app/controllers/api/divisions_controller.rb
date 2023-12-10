module Api
  class DivisionsController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index]

    respond_to :json

    def index
      if tournament
        divisions = division_levels
                    .map { |t| DivisionLevelSerializer.new(t, tournament_id: tournament.id, season_id: season.id) }
        render json: { data: divisions }
      else
        not_found
      end
    end

    private

    def division_levels
      Division.includes(:leagues).joins(:leagues)
              .where('leagues.season_id = ? AND leagues.tournament_id = ?', season.id, tournament.id).uniq(&:level)
    end

    def tournament
      @tournament ||= Tournament.find_by(id: params[:tournament_id])
    end

    def season
      @season ||= Season.find_by(id: params[:season_id]) || Season.last
    end
  end
end
