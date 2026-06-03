module Players
  module Transfermarkt
    class PositionParser < ApplicationService
      TM_POSITION_ID_MAP = {
        1 => 'GK',
        2 => 'CB',
        3 => 'SW',
        4 => 'LB',
        5 => 'RB',
        6 => 'DM',
        7 => 'CM',
        8 => 'LM',
        9 => 'RM',
        10 => 'AM',
        11 => 'LW',
        12 => 'RW',
        13 => 'SS',
        14 => 'CF'
      }.freeze

      CACHE_TTL = 7 * 86_400
      API_URL = 'https://www.transfermarkt.com/ceapi/performance-game'.freeze

      attr_reader :player, :year

      def initialize(player, year)
        @player = player
        @year = year
      end

      def call
        return {} unless player&.tm_id

        mantra_hash
      end

      private

      def mantra_hash
        hash = {}
        positions_hash.each do |tm_pos, number|
          mantra_pos = Position::TM_POSITION_MAP[tm_pos]
          hash[mantra_pos] = hash[mantra_pos].to_i + number
        end
        hash
      end

      def positions_hash
        hash = {}
        performance_data.each do |game|
          next unless game.dig('gameInformation', 'seasonId') == year
          next if game.dig('gameInformation', 'isNationalGame')

          pos_id = game.dig('statistics', 'generalStatistics', 'positionId')
          next unless pos_id

          pos_name = TM_POSITION_ID_MAP[pos_id]
          next unless pos_name

          hash[pos_name] = hash[pos_name].to_i + 1
        end
        hash
      end

      def performance_data
        @performance_data ||= fetch_performance_data
      end

      def fetch_performance_data
        cached = read_cache
        return cached if cached

        fetch_from_api
      rescue RestClient::Exception => e
        Rails.logger.warn("PositionParser: HTTP error for tm_id #{player.tm_id}: #{e}")
        []
      end

      def fetch_from_api
        response = RestClient::Request.execute(
          method: :get,
          url: "#{API_URL}/#{player.tm_id}",
          headers: {
            'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0',
            'Accept' => 'application/json',
            'X-Requested-With' => 'XMLHttpRequest'
          },
          verify_ssl: false
        )
        data = JSON.parse(response.body).dig('data', 'performance') || []
        write_cache(data)
        data
      end

      def cache_path
        Rails.root.join('tmp', 'transfermarkt_cache', "positions_#{player.tm_id}.json")
      end

      def read_cache
        return nil unless cache_path.exist?
        return nil if (Time.zone.now.to_i - cache_path.mtime.to_i) > CACHE_TTL

        JSON.parse(cache_path.read)
      rescue JSON::ParserError
        nil
      end

      def write_cache(data)
        FileUtils.mkdir_p(cache_path.dirname)
        cache_path.write(JSON.generate(data))
      end
    end
  end
end
