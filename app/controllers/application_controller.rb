class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  around_action :switch_locale

  private

  def switch_locale(&action)
    locale = params[:locale] || session[:locale] || I18n.default_locale
    session[:locale] = locale
    I18n.with_locale(locale, &action)
  end

  def after_sign_in_path_for(resource)
    return tour_path(current_user.active_league&.active_tour_or_last) if current_user&.active_league

    stored_location_for(resource) || articles_path
  end

  def after_sign_up_path_for(resource)
    return tour_path(current_user.active_league&.active_tour_or_last) if current_user&.active_league

    stored_location_for(resource) || articles_path
  end
end
