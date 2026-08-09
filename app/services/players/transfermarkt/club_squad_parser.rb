module Players
  module Transfermarkt
    class ClubSquadParser < ApplicationService
      include RetriableApi

      API_URL = 'https://tmapi-alpha.transfermarkt.technology/club'.freeze

      attr_reader :tm_club_id

      def initialize(tm_club_id)
        @tm_club_id = tm_club_id
      end

      def call
        return [] if tm_club_id.blank?

        Array(data['playerIds']).map(&:to_s)
      rescue ApiError => e
        Rails.logger.warn("TM API failed (#{e.message}) for club tm_id=#{tm_club_id}, falling back to HTML parser")
        Players::Transfermarkt::ClubSquadHtmlParser.call(tm_club_id)
      end

      private

      def data
        @data ||= JSON.parse(execute_with_retry(label: "club tm_id=#{tm_club_id}").body)['data'] || {}
      rescue JSON::ParserError
        {}
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
