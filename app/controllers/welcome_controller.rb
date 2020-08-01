class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :html

  def index
    @tournaments = Tournament.with_clubs

    redirect_to articles_path if user_signed_in?
  end
end
