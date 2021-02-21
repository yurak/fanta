class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :html

  helper_method :active_leagues

  def index
    redirect_to tour_path(current_user.active_league.active_tour_or_last) if user_signed_in?
  end

  private

  def active_leagues
    League.active
  end
end
