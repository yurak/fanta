class JoinRequestsController < ApplicationController
  respond_to :html

  def new
    @tournaments = Tournament.mantra
  end

  def create
    join_request = JoinRequest.new(join_request_params.merge(user: current_user))

    if join_request.save
      join_request.user.configured!
      redirect_to joins_path
    else
      @tournaments = Tournament.mantra
      render :new
    end
  end

  private

  def join_request_params
    params.require(:join_request).permit(leagues: [])
  end
end
