class LeaderboardController < ApplicationController
  skip_before_action :authenticate_user!, only: :index
  layout 'react_application', only: :index

  def index; end
end
