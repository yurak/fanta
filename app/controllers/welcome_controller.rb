class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :html

  def index
    redirect_to teams_path if user_signed_in?
  end

  def rules; end
end
