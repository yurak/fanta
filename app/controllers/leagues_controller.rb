class LeaguesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  respond_to :html

  def index
    @leagues = League.active

    respond_with @leagues
  end
end
