module Manage
  class NationalTeamsController < BaseController
    def index
      @tournaments = Tournament.order(:name)
      @national_teams = NationalTeam.includes(:tournament)
                                    .left_joins(:players)
                                    .group(:id)
                                    .select('national_teams.*, COUNT(players.id) AS players_count')
                                    .order(id: :desc)
      @national_teams = @national_teams.where('national_teams.name ILIKE ?', "%#{params[:name]}%") if params[:name].present?
      @national_teams = @national_teams.where(tournament_id: params[:tournament_id]) if params[:tournament_id].present?
      @national_teams = @national_teams.where(status: params[:status]) if params[:status].present?
      @national_teams = @national_teams.page(params[:page]).per(PER_PAGE)
    end

    def show
      @national_team = NationalTeam.includes(:tournament).find(params[:id])
      @players = @national_team.players.order(:name)
      @players_count = @players.size
    end
  end
end
