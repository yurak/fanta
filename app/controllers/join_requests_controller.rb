class JoinRequestsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create success_request]

  respond_to :html

  def new
    @join_request = JoinRequest.new
  end

  def create
    @join_request = JoinRequest.new(join_request_params)
    if @join_request.save
      redirect_to success_request_path
    else
      render :new
    end
  end

  def success_request; end

  private

  def join_request_params
    params.require(:join_request).permit(:username, :contact, :email, { leagues: [] })
  end
end
