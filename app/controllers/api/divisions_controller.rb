module Api
  class DivisionsController < Api::ApplicationController
    skip_before_action :authenticate_user!, only: %i[index]

    respond_to :json

    def index
      if tournament
        divisions = division_levels
                    .map { |t| DivisionLevelSerializer.new(t, tournament_id: tournament.id, season_id: season.id) }
        render json: { data: divisions, meta: meta }
      else
        not_found
      end
    end

    private

    def meta
      {
        season_id: season.id,
        my_league_ids: my_entries.map(&:first).uniq,
        my_team_ids: my_entries.map(&:last).uniq
      }
    end

    def my_entries
      return @my_entries if defined?(@my_entries)
      return @my_entries = [] unless current_user

      @my_entries = Result.joins(:team, :league)
                          .where(teams: { user_id: current_user.id })
                          .where(leagues: { tournament_id: tournament.id, season_id: season.id })
                          .pluck('results.league_id', 'results.team_id')
    end

    def division_levels
      Division.joins(:leagues)
              .where('leagues.season_id = ? AND leagues.tournament_id = ?', season.id, tournament.id)
              .order(:level).uniq(&:level)
    end

    def tournament
      return @tournament if defined?(@tournament)

      @tournament = Tournament.find_by(id: params[:tournament_id])
    end

    def season
      @season ||= Season.find_by(id: params[:season_id]) || Season.last
    end
  end
end
