class WelcomeController < ApplicationController
  respond_to :html

  def index
    redirect_to teams_path if user_signed_in?
  end

  def rules; end
end
