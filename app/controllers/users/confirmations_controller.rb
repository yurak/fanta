module Users
  class ConfirmationsController < Devise::ConfirmationsController
    def index
      @email = User.find(params[:user])&.email
    end

    protected

    def after_confirmation_path_for(_resource_name, resource)
      edit_password_path(resource, reset_password_token: resource.send(:set_reset_password_token))
    end
  end
end
