class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :setup_user
  around_action :switch_locale

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end

  def switch_locale(&action)
    locale = current_user&.locale&.to_sym || params[:locale] || session[:locale] || I18n.default_locale
    locale = I18n.default_locale if I18n.available_locales.exclude?(locale.to_sym)
    session[:locale] = locale
    I18n.with_locale(locale, &action)
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || leagues_path
  end

  def setup_user
    return if !current_user || current_user.configured?

    if current_user.initial?
      redirect_to_new_name
    elsif current_user.named?
      redirect_to_new_avatar
    else
      redirect_to_site_config
    end
  end

  def redirect_to_new_name
    redirect_to new_name_user_path(current_user) unless params[:action] == 'new_name' || params[:action] == 'new_update'
  end

  def redirect_to_new_avatar
    redirect_to new_avatar_user_path(current_user) unless params[:action] == 'new_avatar' || params[:action] == 'new_update'
  end

  def redirect_to_site_config
    redirect_to site_config_user_path(current_user) unless params[:action] == 'site_config' || params[:action] == 'new_update'
  end
end
