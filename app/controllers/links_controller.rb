class LinksController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :html

  def index
    @links = Link.all
  end
end
