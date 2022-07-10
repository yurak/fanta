class JoinRequestsController < ApplicationController
  respond_to :html

  def create
    join_request = JoinRequest.new(join_request_params.merge(user: current_user))

    if join_request.save
      join_request.user.configured!
      redirect_to join_requests_path
    else
      render :new
    end
  end

  private

  def join_request_params
    params.require(:join_request).permit(leagues: [])
  end
end
