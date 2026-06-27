module Manage
  class UsersController < BaseController
    def index
      @users = User.order(id: :desc)
      @users = @users.where(id: params[:id]) if params[:id].present?
      @users = @users.where('email LIKE ?', "%#{params[:email]}%") if params[:email].present?
      @users = @users.page(params[:page]).per(PER_PAGE)
    end

    def show
      @user = User.includes(:user_profile, :user_titles, teams: %i[league tournament results]).find(params.expect(:id))
      @results = Result.joins(:team).where(teams: { user_id: @user.id }).includes(league: :season, team: :tournament).order(id: :desc)
    end
  end
end
