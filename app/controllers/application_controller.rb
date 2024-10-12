class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :setup_user
  around_action :switch_locale

  private

  def switch_locale(&action)
    locale = params[:locale] || session[:locale] || I18n.default_locale
    locale = I18n.default_locale if I18n.available_locales.exclude?(locale.to_sym)
    session[:locale] = locale
    I18n.with_locale(locale, &action)
  end

  def after_sign_in_path_for(resource)
    return tour_path(resource.active_league.active_tour_or_last) if resource.active_league&.active_tour_or_last

    stored_location_for(resource) || articles_path
  end

  def setup_user
    return if !current_user || current_user.configured?

    if current_user.initial?
      redirect_to_new_name
    elsif current_user.named?
      redirect_to_new_avatar
    elsif current_user.with_avatar?
      redirect_to_new_team
    elsif current_user.with_team?
      redirect_to_join_request
    end
  end

  def redirect_to_new_name
    redirect_to new_name_user_path(current_user) unless params[:action] == 'new_name' || params[:action] == 'new_update'
  end

  def redirect_to_new_avatar
    redirect_to new_avatar_user_path(current_user) unless params[:action] == 'new_avatar' || params[:action] == 'new_update'
  end

  def redirect_to_join_request
    redirect_to new_join_request_path if params[:controller] != 'join_requests'
  end

  def redirect_to_new_team
    redirect_to new_team_path if params[:controller] != 'teams'
  end
end
