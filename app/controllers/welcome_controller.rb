class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :html

  def index
    redirect_to leagues_path if current_user
  end

  # TODO: temp redirect
  def fees
    redirect_to rules_path
  end
end
