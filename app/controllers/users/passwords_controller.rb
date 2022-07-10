module Users
  class PasswordsController < Devise::PasswordsController
    def index
      @email = params[:email]
    end

    protected

    def after_sending_reset_password_instructions_path_for(_resource_name)
      users_passwords_path(email: params[:user][:email])
    end
  end
end
