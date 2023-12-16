module Api
  class ApplicationController < ActionController::Base
    before_action :authenticate_user!

    NOT_FOUND_MSG = 'Resource not found'.freeze
    NOT_FOUND_KEY = 'not_found'.freeze

    def not_found
      render json: { errors: [{ key: NOT_FOUND_KEY, message: NOT_FOUND_MSG }] }, status: :not_found
    end

    def response_options(collection)
      @response_options ||= {
        size: page.present? ? collection.total_count : collection.size,
        page: {
          per_page: collection.limit_value,
          total_pages: collection.total_pages,
          current_page: collection.current_page
        }
      }
    end

    def page
      params[:page].present? ? params.require(:page).permit(:size, :number, :limit, :offset) : {}
    end
  end
end
