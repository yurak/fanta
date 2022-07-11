module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    def after_inactive_sign_up_path_for(resource)
      users_confirmations_path(user: resource)
    end
  end
end
