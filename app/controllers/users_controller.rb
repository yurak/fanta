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

  def new_update
    user_add_params = user.initial? && user_params[:name].present? ? user_params.merge(status: :named) : user_params
    user_add_params = user.named? && user_params[:avatar].present? ? user_add_params.merge(status: :with_avatar) : user_add_params
    user.assign_attributes(user_add_params)

    if !user.initial? && user.save
      redirect_to user.named? ? new_avatar_user_path(user) : new_team_path
    else
      redirect_to new_name_user_path(user)
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
    params.permit(:active_team_id, :avatar, :name, :notifications, :ital_pos_naming)
  end
end
