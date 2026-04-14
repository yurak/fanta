module Manage
  class TeamsController < BaseController
    PER_PAGE = 30

    def index
      @teams = Team.includes(:tournament, :league, :user).order(id: :desc)
      @teams = @teams.where('human_name LIKE ?', "%#{params[:name]}%") if params[:name].present?
      @teams = @teams.page(params[:page]).per(PER_PAGE)
    end
  end
end
