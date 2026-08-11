module Api
  class ApplicationController < ActionController::Base
    before_action :authenticate_user!
    before_action :disable_http_cache

    NOT_FOUND_MSG = 'Resource not found'.freeze
    NOT_FOUND_KEY = 'not_found'.freeze
    MAX_PER_PAGE = 100

    def not_found
      render json: { errors: [{ key: NOT_FOUND_KEY, message: NOT_FOUND_MSG }] }, status: :not_found
    end

    def disable_http_cache
      response.headers['Cache-Control'] = 'no-store'
    end

    def response_options(collection)
      @response_options ||= {
        size: collection.total_count,
        page: {
          per_page: collection.limit_value,
          total_pages: collection.total_pages,
          current_page: collection.current_page
        }
      }
    end

    def page
      params[:page].present? ? params.expect(page: %i[size number limit offset]) : {}
    end

    def paginate(result)
      collection = result.is_a?(Array) ? Kaminari.paginate_array(result) : result

      collection.page(page[:number]).per(page_size)
    end

    def page_size
      (page[:size].presence || MAX_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)
    end
  end
end
