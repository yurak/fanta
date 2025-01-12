class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show_manager]
  before_action :check_user, except: %i[show_manager]
  skip_before_action :verify_authenticity_token, only: :update

  respond_to :html, :json

  helper_method :user

  def update
    user.update(user_params)

    redirect_to user_path(user)
  end

  def new_name
    user.create_user_profile unless user.user_profile
  end

  def new_update
    user_add_params = user_new_params
    user_add_params = user_add_params.merge(status: :with_avatar) if user.named? && user_params[:avatar].present?
    user.assign_attributes(user_add_params)

    if !user.initial? && user.save
      update_user_profile

      redirect_to user.named? ? new_avatar_user_path(user) : new_team_path
    else
      redirect_to new_name_user_path(user)
    end
  end

  def show_manager
    @user = User.find(params[:id])
  end

  private

  def check_user
    redirect_to user_path(user) unless current_user.id == params[:id].to_i
  end

  def update_user_profile
    user.user_profile&.update(user_profile_params)
  end

  def user
    @user ||= current_user
  end

  def user_params
    params.permit(:avatar, :name, :notifications, :ital_pos_naming)
  end

  def user_new_params
    user.initial? && user_params[:name].present? ? user_params.merge(status: :named) : user_params
  end

  def user_profile_params
    params.permit(:tg_name)
  end
end
