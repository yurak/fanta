module Manage
  class TeamsController < BaseController
    def index
      @teams = Team.includes(:tournament, :league, :user).order(id: :desc)
      @teams = @teams.where(id: params[:id]) if params[:id].present?
      @teams = @teams.where('human_name ILIKE ?', "%#{params[:name]}%") if params[:name].present?
      @teams = @teams.page(params[:page]).per(PER_PAGE)
    end
  end
end
