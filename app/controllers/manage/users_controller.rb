module Manage
  class UsersController < BaseController
    PER_PAGE = 30

    def index
      @users = User.order(id: :desc)
      @users = @users.where(id: params[:id]) if params[:id].present?
      @users = @users.where('email LIKE ?', "%#{params[:email]}%") if params[:email].present?
      @users = @users.page(params[:page]).per(PER_PAGE)
    end

    def show
      @user = User.includes(:user_profile, teams: %i[league tournament]).find(params[:id])
    end
  end
end
