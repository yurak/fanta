module Players
  module Transfermarkt
    class ClubSquadParser < ApplicationService
      API_URL = 'https://tmapi-alpha.transfermarkt.technology/club'.freeze

      attr_reader :tm_club_id

      def initialize(tm_club_id)
        @tm_club_id = tm_club_id
      end

      def call
        return [] if tm_club_id.blank?

        Array(data['playerIds']).map(&:to_s)
      end

      private

      def data
        @data ||= JSON.parse(execute_with_retry.body)['data'] || {}
      rescue JSON::ParserError
        {}
      end

      def execute_with_retry
        retries = 0
        begin
          api_request
        rescue Errno::ECONNRESET, OpenSSL::SSL::SSLError, RestClient::ServerBrokeConnection => e
          retries += 1
          raise if retries > 3

          wait = retries * 10
          Rails.logger.info "#{e.class} for club tm_id=#{tm_club_id}, retry #{retries}/3 in #{wait}s..."
          sleep(wait)
          retry
        end
      end

      def api_request
        RestClient::Request.execute(
          method: :get,
          url: "#{API_URL}/#{tm_club_id}/squad",
          headers: {
            'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0',
            'Accept' => 'application/json'
          },
          verify_ssl: false
        )
      end
    end
  end
end
