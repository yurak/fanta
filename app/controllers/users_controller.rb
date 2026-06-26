class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show_manager]
  before_action :check_user, except: %i[show_manager]
  skip_before_action :verify_authenticity_token, only: :update

  respond_to :html, :json

  helper_method :user

  def show
    leagues = current_user.teams.map(&:league).compact
    ActiveRecord::Associations::Preloader.new(records: leagues, associations: %i[division season]).call
  end

  def update
    user.update(user_params)
    update_user_profile

    redirect_to user_path(user)
  end

  def new_name
    user.create_user_profile unless user.user_profile
  end

  def site_config; end

  def new_update
    user_add_params = user_new_params
    user_add_params = user_add_params.merge(status: :with_avatar) if user.named? && user_params[:avatar].present?
    user_add_params = user_add_params.merge(status: :configured) if user.with_avatar?
    user.assign_attributes(user_add_params)

    if !user.initial? && user.save
      update_user_profile

      redirect_to new_update_redirect_path
    else
      redirect_to new_name_user_path(user)
    end
  end

  def telegram_connect
    profile = user.user_profile || user.create_user_profile
    token = SecureRandom.hex(16)
    profile.update(tg_connect_token: token, tg_connect_expires_at: 1.hour.from_now)
    bot_username = Rails.application.config.telegram_updates_controller.bot_username
    render json: { url: "https://t.me/#{bot_username}?start=#{token}" }
  end

  def show_manager
    @user = User.includes(
      teams: {},
      results: { league: %i[tournament division season], team: {} }
    ).find(params.expect(:id))
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
    params.permit(:avatar, :ital_pos_naming, :locale, :name, :notifications, :time_zone)
  end

  def user_new_params
    user.initial? && user_params[:name].present? ? user_params.merge(status: :named) : user_params
  end

  def new_update_redirect_path
    if user.named?
      new_avatar_user_path(user)
    elsif user.configured?
      joins_path
    else
      site_config_user_path(user)
    end
  end

  def user_profile_params
    params.permit(:tg_name, :bot_enabled)
  end
end
