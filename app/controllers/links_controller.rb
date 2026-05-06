class LinksController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :html

  def index
    @tournaments = Tournament.joins(:links).includes(:links).distinct.order(:id)
  end
end
