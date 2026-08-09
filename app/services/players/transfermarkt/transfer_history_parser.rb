module Players
  module Transfermarkt
    class TransferHistoryParser < ApplicationService
      include RetriableApi

      API_URL = 'https://www.transfermarkt.com/ceapi/transferHistory/list'.freeze
      CACHE_TTL = 7 * 86_400

      attr_reader :tm_id

      def initialize(tm_id)
        @tm_id = tm_id
      end

      def call
        return [] unless tm_id

        Array(data['transfers']).filter_map { |raw| normalize(raw) }
      end

      private

      def normalize(raw)
        return nil unless raw['dateUnformatted'].present? && raw.dig('to', 'clubName').present?

        fee = clean_text(raw['fee'])
        {
          tm_transfer_id: transfer_id(raw),
          old_club_name: raw.dig('from', 'clubName').presence, old_tm_club_id: club_id(raw['from']),
          new_club_name: raw.dig('to', 'clubName'), new_tm_club_id: club_id(raw['to']),
          start_date: parse_date(raw['dateUnformatted']),
          season: raw['season'].presence, fee: fee, market_value: clean_text(raw['marketValue']),
          loan: loan?(fee), upcoming: raw['upcoming'] == true || raw['futureTransfer'].to_i.positive?
        }
      end

      def transfer_id(raw)
        raw['url'].to_s[%r{/transfer_id/(\d+)}, 1]&.to_i
      end

      def club_id(side)
        side.to_h['href'].to_s[%r{/verein/(\d+)/}, 1]
      end

      def parse_date(raw)
        Date.parse(raw)
      rescue Date::Error
        nil
      end

      # "loan transfer" → loan; "End of loan" is a permanent return, not a loan.
      def loan?(fee)
        fee.to_s.match?(/loan/i) && !fee.to_s.match?(/end of loan/i)
      end

      def clean_text(str)
        return nil if str.blank?

        str.gsub(%r{<br\s*/?>}i, ' ').gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip.presence
      end

      def data
        @data ||= fetch_data
      end

      def fetch_data
        cached = read_cache
        return cached if cached

        result = JSON.parse(execute_with_retry(label: "tm_id=#{tm_id}").body)
        write_cache(result)
        result
      rescue JSON::ParserError
        {}
      end

      def api_request
        RestClient::Request.execute(
          method: :get,
          url: "#{API_URL}/#{tm_id}",
          headers: {
            'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0',
            'Accept' => 'application/json'
          },
          verify_ssl: false
        )
      end

      def cache_path
        Rails.root.join('tmp', 'transfermarkt_cache', "player_transfers_#{tm_id}.json")
      end

      def cache_disabled?
        ENV['TM_SKIP_CACHE'].present?
      end

      def read_cache
        return nil if cache_disabled?
        return nil unless cache_path.exist?
        return nil if (Time.zone.now.to_i - cache_path.mtime.to_i) > CACHE_TTL

        JSON.parse(cache_path.read)
      rescue JSON::ParserError
        nil
      end

      def write_cache(data)
        return if cache_disabled?

        FileUtils.mkdir_p(cache_path.dirname)
        cache_path.write(JSON.generate(data))
      end
    end
  end
end
