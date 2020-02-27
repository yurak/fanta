class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  private

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || articles_path
  end

  def after_sign_up_path_for(resource)
    stored_location_for(resource) || articles_path
  end
end
