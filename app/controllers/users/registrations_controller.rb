module Users
  class RegistrationsController < Devise::RegistrationsController
    def create
      if User.exists?(email: params[:user][:email].to_s.downcase.strip)
        @email_taken = true
        build_resource(sign_up_params)
        render :new
      else
        super
      end
    end

    protected

    def after_inactive_sign_up_path_for(resource)
      users_confirmations_path(user: resource)
    end
  end
end
