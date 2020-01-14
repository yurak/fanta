module Admin
  class UsersController < ApplicationController
    respond_to :html
    helper_method :user

    def update
      if User.update(user_params)
        redirect_to edit_admin_user_path, notice: 'User was successfully updated.'
      end
    end

    private

    def user_params
      params.require(:user).permit(:summer_balance)
    end

    def user
      @user ||= User.find(params[:id])
    end
  end
end
