module Api
  class ApplicationController < ActionController::Base
    before_action :authenticate_user!

    NOT_FOUND_MSG = 'Resource not found'
    NOT_FOUND_KEY = 'not_found'

    def not_found
      render json: { errors: [{ key: NOT_FOUND_KEY, message: NOT_FOUND_MSG }] }, status: 404
    end
  end
end
