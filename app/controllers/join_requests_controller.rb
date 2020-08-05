class JoinRequestsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create]

  respond_to :html

  def new
    @join_request = JoinRequest.new
  end

  def create; end

  def success_request; end
end
