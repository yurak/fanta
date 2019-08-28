class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  helper_method :active_tour

  private

  def active_tour
    Tour.set_lineup.first || Tour.locked.first
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || articles_path
  end

  def after_sign_up_path_for(resource)
    stored_location_for(resource) || articles_path
  end
end
