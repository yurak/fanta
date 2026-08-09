module Players
  module Transfermarkt
    class ClubSquadHtmlParser < ApplicationService
      include RetriableApi

      SQUAD_URL = 'https://www.transfermarkt.com/club/kader/verein'.freeze
      USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0'.freeze

      attr_reader :tm_club_id

      def initialize(tm_club_id)
        @tm_club_id = tm_club_id
      end

      def call
        return [] if tm_club_id.blank?

        html_page.css('table.items td.hauptlink a[href*="/profil/spieler/"]')
                 .filter_map { |link| link['href'].to_s[%r{/spieler/(\d+)}, 1] }
                 .uniq
      end

      private

      def html_page
        @html_page ||= Nokogiri::HTML(execute_with_retry(label: "club tm_id=#{tm_club_id}").body)
      end

      def api_request
        RestClient::Request.execute(
          method: :get,
          url: "#{SQUAD_URL}/#{tm_club_id}/plus/1",
          headers: { 'User-Agent' => USER_AGENT },
          verify_ssl: false
        )
      end
    end
  end
end
