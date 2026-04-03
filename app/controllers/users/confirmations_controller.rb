module Users
  class ConfirmationsController < Devise::ConfirmationsController
    def index
      @email = User.find(params[:user])&.email
    end

    def show
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])

      if resource.errors[:email].include?(I18n.t('errors.messages.already_confirmed'))
        if resource.encrypted_password.blank?
          redirect_to edit_password_path(resource, reset_password_token: resource.send(:set_reset_password_token))
        else
          redirect_to new_user_session_path, alert: t('devise.confirmations.already_confirmed')
        end
        return
      end

      super
    end

    protected

    def after_confirmation_path_for(_resource_name, resource)
      edit_password_path(resource, reset_password_token: resource.send(:set_reset_password_token))
    end
  end
end
