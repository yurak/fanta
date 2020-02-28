class LeaguesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  respond_to :html

  def index
    # TODO: show only active leagues
    @leagues = League.all

    respond_with @leagues
  end
end
