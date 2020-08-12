class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  around_action :switch_locale

  private

  def switch_locale(&action)
    locale ||= params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || articles_path
  end

  def after_sign_up_path_for(resource)
    stored_location_for(resource) || articles_path
  end
end
