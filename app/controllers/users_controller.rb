class UsersController < ApplicationController
  before_action :check_user

  respond_to :html, :json

  helper_method :user

  def update
    user.update(user_params)

    if user_params[:active_team_id]
      redirect_back(fallback_location: root_path)
    else
      redirect_to user_path(user)
    end
  end

  private

  def check_user
    redirect_to user_path(user) unless current_user.id == params[:id].to_i
  end

  def user
    @user ||= current_user
  end

  def user_params
    params.permit(:name, :active_team_id, :notifications, :avatar)
  end
end
