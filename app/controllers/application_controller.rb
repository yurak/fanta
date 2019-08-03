class ApplicationController < ActionController::Base
  helper_method :active_tours

  private

  def active_tours
    Tour.set_lineup
  end
end
