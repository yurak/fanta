module Players
  module Fotmob
    class IdFinder < ApplicationService
      SEARCH_URL = 'https://apigw.fotmob.com/searchapi/suggest'.freeze

      def initialize(name)
        @name = name.to_s.strip
      end

      def call
        return [] if @name.blank?

        fetch_options.filter_map { |option| build_candidate(option) }
      end

      private

      def build_candidate(option)
        payload = option['payload'] || {}
        id = payload['id'].presence
        return nil unless id

        { id: id, name: option['text'].to_s.split('|').first, team_name: payload['teamName'] }
      end

      def fetch_options
        body = fetch
        return [] unless body

        json = JSON.parse(body)
        Array(json['squadMemberSuggest']).flat_map { |suggest| Array(suggest['options']) }
      rescue JSON::ParserError
        []
      end

      def fetch
        RestClient::Request.execute(
          method: :get,
          url: "#{SEARCH_URL}?term=#{CGI.escape(@name)}&lang=en",
          headers: { 'User-Agent' => 'Mozilla/5.0' },
          timeout: 20
        ).body
      rescue RestClient::Exception
        nil
      end
    end
  end
end
