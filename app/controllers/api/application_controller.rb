module Api
  class ApplicationController < ActionController::Base
    before_action :authenticate_user!

    NOT_FOUND_MSG = 'Resource not found'.freeze
    NOT_FOUND_KEY = 'not_found'.freeze

    def not_found
      render json: { errors: [{ key: NOT_FOUND_KEY, message: NOT_FOUND_MSG }] }, status: :not_found
    end
  end
end
