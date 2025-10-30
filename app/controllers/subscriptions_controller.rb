class SubscriptionsController < ApplicationController
  skip_before_action :authenticate_user!

  helper_method :user

  def unsubscribe; end

  def confirm_unsubscribe
    user&.update(subscribed: false)

    redirect_to root_path
  end

  private

  def user
    @user ||= User.find_by(unsubscribe_token: params[:token])
  end
end
