module Players
  module Transfermarkt
    class ApiParser < ApplicationService
      NATIONALITY_MAP = {
        2 => 'eg', 3 => 'al', 4 => 'dz', 5 => 'ad', 6 => 'ao', 7 => 'ag', 8 => 'gq',
        9 => 'ar', 10 => 'am', 12 => 'au', 13 => 'az', 16 => 'bd', 17 => 'bb', 18 => 'by',
        19 => 'be', 21 => 'bj', 23 => 'bo', 24 => 'ba', 25 => 'bw', 26 => 'br', 28 => 'bg',
        29 => 'bf', 30 => 'bi', 31 => 'cm', 32 => 'cv', 33 => 'cl', 34 => 'cn', 35 => 'km',
        36 => 'cr', 37 => 'hr', 38 => 'ci', 39 => 'dk', 40 => 'de', 43 => 'do', 44 => 'ec',
        45 => 'sv', 47 => 'ee', 48 => 'fj', 49 => 'fi', 50 => 'fr', 51 => 'ga', 52 => 'gm',
        53 => 'ge', 54 => 'gh', 55 => 'gd', 56 => 'gr', 58 => 'gt', 59 => 'gn', 60 => 'gw',
        61 => 'gy', 62 => 'ht', 66 => 'hn', 68 => 'id', 70 => 'iq', 71 => 'ir', 72 => 'ie',
        73 => 'is', 74 => 'il', 75 => 'it', 76 => 'jm', 77 => 'jp', 78 => 'jo', 80 => 'ca',
        81 => 'kz', 82 => 'ke', 83 => 'co', 85 => 'cg', 87 => 'kr', 88 => 'cu', 90 => 'kg',
        92 => 'lv', 94 => 'lb', 95 => 'lr', 96 => 'ly', 98 => 'lt', 99 => 'lu', 100 => 'mk',
        101 => 'mg', 102 => 'mw', 103 => 'my', 105 => 'ml', 106 => 'mt', 107 => 'ma',
        108 => 'mr', 110 => 'mx', 112 => 'md', 115 => 'mz', 117 => 'na', 120 => 'nz',
        121 => 'ni', 122 => 'nl', 123 => 'ne', 124 => 'ng', 125 => 'no', 127 => 'at',
        128 => 'pk', 130 => 'pa', 132 => 'py', 133 => 'pe', 134 => 'ph', 135 => 'pl',
        136 => 'pt', 137 => 'qa', 138 => 'cf', 139 => 'rw', 140 => 'ro', 141 => 'ru',
        142 => 'zm', 145 => 'st', 146 => 'sa', 147 => 'se', 148 => 'ch', 149 => 'sn',
        152 => 'sl', 154 => 'sk', 155 => 'si', 156 => 'so', 157 => 'es', 159 => 'za',
        160 => 'sd', 161 => 'sr', 163 => 'sy', 165 => 'tj', 166 => 'tz', 167 => 'th',
        168 => 'tg', 170 => 'tt', 171 => 'td', 172 => 'cz', 173 => 'tn', 174 => 'tr',
        176 => 'ug', 177 => 'ua', 178 => 'hu', 179 => 'uy', 180 => 'uz', 182 => 've',
        183 => 'ae', 184 => 'us', 187 => 'zw', 188 => 'cy', 189 => 'gb-eng', 190 => 'gb-sct',
        191 => 'gb-wls', 192 => 'gb-nir', 193 => 'cd', 207 => 'mq', 208 => 'fo', 211 => 'bm',
        215 => 'rs', 216 => 'me', 225 => 'kn', 228 => 'pr', 230 => 'lc', 235 => 'ms',
        236 => 'nc', 240 => 'ps', 244 => 'xk', 251 => 'gp', 252 => 'gf', 260 => 'cw',
        269 => 'bq', 270 => 'im'
      }.freeze

      API_URL = 'https://tmapi-alpha.transfermarkt.technology/player'.freeze
      CACHE_TTL = 7 * 86_400

      attr_reader :tm_id, :position_skip

      def initialize(tm_id, position_skip: false)
        @tm_id = tm_id
        @position_skip = position_skip
      end

      def call
        return false unless tm_id

        {
          first_name: first_name, name: last_name, nationality: nationality,
          club_id: club&.id, club_name: club&.name, tm_club_name: tm_club_name, tm_club_id: tm_club_id,
          position1: position1, position2: position2, position3: position3,
          tm_url: tm_url, tm_pos1: tm_pos1, tm_pos2: tm_pos2, tm_pos3: tm_pos3,
          tm_price: price, number: number, birth_date: birth_date, height: height
        }
      end

      private

      def first_name
        parts = data['name'].to_s.split
        parts.length > 1 ? parts[0..-2].join(' ') : nil
      end

      def last_name
        data['name'].to_s.split.last
      end

      def nationality
        nat_id = data.dig('nationalityDetails', 'nationalities', 'nationalityId')
        NATIONALITY_MAP[nat_id]
      end

      def birth_date
        raw = data.dig('lifeDates', 'dateOfBirth')
        return nil unless raw

        Date.parse(raw).strftime('%d/%m/%Y')
      rescue Date::Error
        nil
      end

      def height
        h = data.dig('attributes', 'height')
        return nil unless h

        (h * 100).round
      end

      def price
        data.dig('marketValueDetails', 'current', 'value').to_i
      end

      def number
        current_assignment&.dig('shirtNumber')
      end

      def tm_club_name
        @tm_club_name ||= club&.tm_name
      end

      def club
        return nil if tm_club_id.blank?

        @club ||= Club.all.find { |c| c.tm_url.to_s.split('/').last == tm_club_id } ||
          Club.all.find { |c| c.reserve_club_ids&.include?(tm_club_id) }
      end

      def tm_club_id
        current_assignment&.dig('clubId')&.to_s
      end

      def current_assignment
        @current_assignment ||= Array(data['clubAssignments']).find { |a| a['type'] == 'current' }
      end

      def tm_pos1
        data.dig('attributes', 'position', 'shortName')
      end

      def tm_pos2
        data.dig('attributes', 'firstSidePosition', 'shortName')
      end

      def tm_pos3
        data.dig('attributes', 'secondSidePosition', 'shortName')
      end

      def position_arr
        return [] if position_skip

        @position_arr ||= Players::Transfermarkt::PositionMapper.call(
          Player.new(tm_id: tm_id),
          Season.last.start_year,
          base_positions: [tm_pos1, tm_pos2, tm_pos3]
        )
      end

      def position1
        Position::HUMAN_MAP[position_arr[0]] if position_arr[0]
      end

      def position2
        Position::HUMAN_MAP[position_arr[1]] if position_arr[1]
      end

      def position3
        Position::HUMAN_MAP[position_arr[2]] if position_arr[2]
      end

      def tm_url
        "#{Player::TM_PATH}#{tm_id}"
      end

      def data
        @data ||= fetch_data
      end

      def fetch_data
        cached = read_cache
        return cached if cached

        result = JSON.parse(execute_with_retry.body)['data']
        write_cache(result)
        result
      end

      def execute_with_retry
        retries = 0
        begin
          api_request
        rescue Errno::ECONNRESET, OpenSSL::SSL::SSLError, RestClient::ServerBrokeConnection => e
          retries += 1
          raise if retries > 3

          wait = retries * 10
          Rails.logger.info "#{e.class} for tm_id=#{tm_id}, retry #{retries}/3 in #{wait}s..."
          sleep(wait)
          retry
        end
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
        Rails.root.join('tmp', 'transfermarkt_cache', "player_api_#{tm_id}.json")
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
