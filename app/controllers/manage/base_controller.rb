module Manage
  class BaseController < ApplicationController
    PER_PAGE = 20

    before_action :require_admin!

    private

    def require_admin!
      redirect_to leagues_path unless current_user&.admin?
    end
  end
end
