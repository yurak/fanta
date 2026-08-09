module Players
  module Transfermarkt
    class ApiError < StandardError
      attr_reader :http_code

      def initialize(message, http_code: nil)
        @http_code = http_code
        super(message)
      end
    end

    # The host itself cannot be reached (dead DNS, no route). Retrying is pointless,
    # so callers fall back to the HTML parsers instead of sleeping through the retries.
    class ApiUnavailableError < ApiError; end

    module RetriableApi
      MAX_RETRIES = 3
      UNREACHABLE_ERRORS = [SocketError, Errno::EHOSTUNREACH, Errno::ENETUNREACH].freeze
      # A TLS alert means the server refuses to serve this host at all. Retrying only stalls
      # the request for a minute before the caller can fall back.
      FATAL_SSL_MESSAGE = /handshake failure|unknown ca|certificate verify failed|no cipher/i
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
        rescue *UNREACHABLE_ERRORS, *CONNECTION_ERRORS, RestClient::ExceptionWithResponse => e
          raise ApiUnavailableError, describe(e) if unreachable?(e)
          raise wrap_error(e) unless retriable?(e)

          retries += 1
          raise wrap_error(e) if retries > MAX_RETRIES

          wait = retries * 10
          Rails.logger.info "#{describe(e)} for #{label}, retry #{retries}/#{MAX_RETRIES} in #{wait}s..."
          sleep(wait)
          retry
        end
      end

      def unreachable?(error)
        return true if UNREACHABLE_ERRORS.any? { |klass| error.is_a?(klass) }

        error.is_a?(OpenSSL::SSL::SSLError) && error.message.match?(FATAL_SSL_MESSAGE)
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
