module Scores
  module Injectors
    class FotmobPage
      BASE_URL = 'https://www.fotmob.com'.freeze
      USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
                   '(KHTML, like Gecko) Chrome/124.0 Safari/537.36'.freeze
      REQUEST_TIMEOUT = 15
      MAX_RETRIES = 2
      BACKOFF_SECONDS = 5
      REDIRECT_ERRORS = [
        RestClient::MovedPermanently, RestClient::Found,
        RestClient::TemporaryRedirect, RestClient::PermanentRedirect
      ].freeze

      TRANSIENT_ERRORS = [
        RestClient::ServerBrokeConnection, RestClient::Exceptions::Timeout,
        Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ETIMEDOUT, OpenSSL::SSL::SSLError, SocketError
      ].freeze

      attr_reader :failure

      def initialize(match, budget:)
        @match = match
        @budget = budget
      end

      def html
        by_id = fetch_by_match_id
        return by_id if by_id

        fetch_by_page_url
      end

      private

      attr_reader :match

      def fetch_by_match_id
        return nil if match_id_path.nil?

        attempt = 0
        begin
          attempt += 1
          execute_get(match_id_path)
        rescue RestClient::ExceptionWithResponse, *TRANSIENT_ERRORS => e
          retry if retry_after_backoff?(e, attempt)
          return nil if match.page_url.present?

          record_failure(failure_kind(e), e, match_id_path)
        end
      end

      def fetch_by_page_url
        return nil if match.page_url.blank?

        attempt = 0
        begin
          attempt += 1
          execute_get(match.page_url)
        rescue *REDIRECT_ERRORS => e
          retry if follow_redirect?(e)

          record_failure(:health, e, match.page_url)
        rescue RestClient::ExceptionWithResponse, *TRANSIENT_ERRORS => e
          retry if retry_after_backoff?(e, attempt)

          record_failure(failure_kind(e), e, match.page_url)
        end
      end

      def match_id_path
        id = match.source_match_id.to_s.strip

        "/match/#{id}" if id.present?
      end

      def execute_get(path)
        RestClient::Request.execute(method: :get, url: "#{BASE_URL}#{path}",
                                    headers: { user_agent: USER_AGENT }, timeout: REQUEST_TIMEOUT)
      end

      def follow_redirect?(error)
        return false if @redirected

        location = error.response&.headers&.dig(:location).to_s
        return false if location.blank?

        @redirected = true
        match.update(page_url: redirected_page_url(location))
        Rails.logger.info("[live-scores] FotMob moved #{match.page_url_previously_was} to #{match.page_url}")
        true
      end

      def redirected_page_url(location)
        path = location.start_with?('http') ? URI.parse(location).path : location
        fragment = match.page_url.to_s[/#.*/]

        "#{path}#{fragment}"
      end

      def retry_after_backoff?(error, attempt)
        return false unless retriable?(error) && attempt <= MAX_RETRIES

        @budget.wait(attempt * BACKOFF_SECONDS).positive?
      end

      def failure_kind(error)
        return :not_found if error.is_a?(RestClient::ResourceNotFound)

        :health
      end

      def retriable?(error)
        return true unless error.is_a?(RestClient::ExceptionWithResponse)

        error.http_code.to_i >= 500
      end

      def record_failure(kind, error, path)
        @failure = kind
        reason = error.is_a?(RestClient::ExceptionWithResponse) ? "HTTP #{error.http_code}" : error.class.to_s
        Rails.logger.warn("[live-scores] FotMob scrape skipped for #{path}: #{reason}")
        nil
      end
    end
  end
end
