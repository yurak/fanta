module Players
  module Transfermarkt
    class ApiError < StandardError
      attr_reader :http_code

      def initialize(message, http_code: nil)
        @http_code = http_code
        super(message)
      end
    end

    module RetriableApi
      MAX_RETRIES = 3
      CONNECTION_ERRORS = [
        Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ETIMEDOUT,
        OpenSSL::SSL::SSLError,
        RestClient::ServerBrokeConnection, RestClient::Exceptions::Timeout
      ].freeze

      private

      def execute_with_retry(label:)
        retries = 0
        begin
          api_request
        rescue *CONNECTION_ERRORS, RestClient::ExceptionWithResponse => e
          raise wrap_error(e) unless retriable?(e)

          retries += 1
          raise wrap_error(e) if retries > MAX_RETRIES

          wait = retries * 10
          Rails.logger.info "#{describe(e)} for #{label}, retry #{retries}/#{MAX_RETRIES} in #{wait}s..."
          sleep(wait)
          retry
        end
      end

      def retriable?(error)
        return true unless error.is_a?(RestClient::ExceptionWithResponse)

        error.http_code.to_i >= 500
      end

      def describe(error)
        return "#{error.class} (HTTP #{error.http_code})" if error.is_a?(RestClient::ExceptionWithResponse)

        error.class.to_s
      end

      def wrap_error(error)
        code = error.http_code if error.is_a?(RestClient::ExceptionWithResponse)
        ApiError.new(describe(error), http_code: code)
      end
    end
  end
end
