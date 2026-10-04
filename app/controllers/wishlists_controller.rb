class WishlistsController < ApplicationController
  skip_before_action :authenticate_user!, only: :show

  layout 'react_application'

  def index; end

  def show; end
end
