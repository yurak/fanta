class UsersController < ApplicationController
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

  def identifier
    params[:user_id].presence || params[:id]
  end

  def user
    @user ||= User.find(identifier)
  end

  def user_params
    params.permit(:name, :active_team_id, :notifications, :avatar)
  end
end
