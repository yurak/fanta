# frozen_string_literal: true

module Players
  module Transfermarkt
    class ApiError < StandardError
      # Transfermarkt answers these when it has blocked the caller rather than when the request is
      # wrong: 405 to a perfectly valid GET, 403 outright, 429 on rate limits.
      BLOCKED_CODES = [403, 405, 429].freeze

      attr_reader :http_code

      def initialize(message, http_code: nil)
        @http_code = http_code
        super(message)
      end

      def blocked?
        BLOCKED_CODES.include?(http_code.to_i)
      end
    end
  end
end
