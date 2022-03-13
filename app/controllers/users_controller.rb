class UsersController < ApplicationController
  before_action :check_user

  respond_to :html, :json

  helper_method :user

  def update
    user.update(user_params)

    if user_params[:active_team_id]
      if user.active_league&.active_tour_or_last
        redirect_to tour_path(user.active_league&.active_tour_or_last)
      else
        redirect_to league_path(user.active_league)
      end
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
