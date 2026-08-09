module Players
  module Transfermarkt
    class ApiParser < ApplicationService
      include RetriableApi

      NATIONALITY_MAP = {
        1 => 'af', 2 => 'eg', 3 => 'al', 4 => 'dz', 5 => 'ad', 6 => 'ao', 7 => 'ag', 8 => 'gq', 9 => 'ar',
        10 => 'am', 11 => 'et', 12 => 'au', 13 => 'az', 14 => 'bs', 15 => 'bh', 16 => 'bd', 17 => 'bb', 18 => 'by', 19 => 'be',
        20 => 'bz', 21 => 'bj', 22 => 'bt', 23 => 'bo', 24 => 'ba', 25 => 'bw', 26 => 'br', 27 => 'bn', 28 => 'bg', 29 => 'bf',
        30 => 'bi', 31 => 'cm', 32 => 'cv', 33 => 'cl', 34 => 'cn', 35 => 'km', 36 => 'cr', 37 => 'hr', 38 => 'ci', 39 => 'dk',
        40 => 'de', 41 => 'dj', 42 => 'dm', 43 => 'do', 44 => 'ec', 45 => 'sv', 46 => 'er', 47 => 'ee', 48 => 'fj', 49 => 'fi',
        50 => 'fr', 51 => 'ga', 52 => 'gm', 53 => 'ge', 54 => 'gh', 55 => 'gd', 56 => 'gr', 58 => 'gt', 59 => 'gn',
        60 => 'gw', 61 => 'gy', 62 => 'ht', 66 => 'hn', 67 => 'in', 68 => 'id', 69 => 'sb',
        70 => 'iq', 71 => 'ir', 72 => 'ie', 73 => 'is', 74 => 'il', 75 => 'it', 76 => 'jm', 77 => 'jp', 78 => 'jo', 79 => 'kh',
        80 => 'ca', 81 => 'kz', 82 => 'ke', 83 => 'co', 85 => 'cg', 86 => 'kp', 87 => 'kr', 88 => 'cu', 89 => 'kw',
        90 => 'kg', 91 => 'la', 92 => 'lv', 93 => 'ls', 94 => 'lb', 95 => 'lr', 96 => 'ly', 97 => 'li', 98 => 'lt', 99 => 'lu',
        100 => 'mk', 101 => 'mg', 102 => 'mw', 103 => 'my', 104 => 'mv', 105 => 'ml', 106 => 'mt', 107 => 'ma', 108 => 'mr', 109 => 'mu',
        110 => 'mx', 111 => 'fm', 112 => 'md', 114 => 'mn', 115 => 'mz', 116 => 'mm', 117 => 'na', 119 => 'np',
        120 => 'nz', 121 => 'ni', 122 => 'nl', 123 => 'ne', 124 => 'ng', 125 => 'no', 126 => 'om', 127 => 'at', 128 => 'pk',
        130 => 'pa', 131 => 'pg', 132 => 'py', 133 => 'pe', 134 => 'ph', 135 => 'pl', 136 => 'pt', 137 => 'qa', 138 => 'cf', 139 => 'rw',
        140 => 'ro', 141 => 'ru', 142 => 'zm', 143 => 'ws', 144 => 'sm', 145 => 'st', 146 => 'sa', 147 => 'se', 148 => 'ch', 149 => 'sn',
        151 => 'sc', 152 => 'sl', 153 => 'sg', 154 => 'sk', 155 => 'si', 156 => 'so', 157 => 'es', 158 => 'lk', 159 => 'za',
        160 => 'sd', 161 => 'sr', 162 => 'sz', 163 => 'sy', 164 => 'tw', 165 => 'tj', 166 => 'tz', 167 => 'th', 168 => 'tg', 169 => 'to',
        170 => 'tt', 171 => 'td', 172 => 'cz', 173 => 'tn', 174 => 'tr', 175 => 'tm', 176 => 'ug', 177 => 'ua', 178 => 'hu', 179 => 'uy',
        180 => 'uz', 181 => 'vu', 182 => 've', 183 => 'ae', 184 => 'us', 185 => 'vn', 186 => 'ye', 187 => 'zw', 188 => 'cy',
        189 => 'gb-eng', 190 => 'gb-sct', 191 => 'gb-wls', 192 => 'gb-nir', 193 => 'cd',
        207 => 'mq', 208 => 'fo',
        211 => 'bm', 215 => 'rs', 216 => 'me', 218 => 'hk', 219 => 'mo',
        224 => 'vc', 225 => 'kn', 226 => 'tc', 228 => 'pr', 229 => 'ky',
        230 => 'lc', 231 => 'vg', 232 => 'ai', 233 => 'aw', 234 => 'vi', 235 => 'ms', 236 => 'nc', 238 => 'ck', 239 => 'as',
        240 => 'ps', 241 => 'gu', 242 => 'tl', 243 => 'gl', 244 => 'xk', 246 => 'ki',
        251 => 'gp', 252 => 'gf',
        260 => 'cw', 262 => 'ss', 266 => 'gi', 268 => 'mp', 269 => 'bq',
        270 => 'im'
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

        api_data
      rescue ApiError => e
        Rails.logger.warn("TM API failed (#{e.message}) for tm_id=#{tm_id}, falling back to HTML parser")
        Players::Transfermarkt::PlayerHtmlParser.call(tm_id, position_skip: position_skip)
      end

      private

      def api_data
        {
          first_name: first_name, name: last_name, nationality: nationality,
          club_id: club&.id, club_name: club&.name, tm_club_name: tm_club_name, tm_club_id: tm_club_id,
          position1: position1, position2: position2, position3: position3,
          tm_url: tm_url, tm_pos1: tm_pos1, tm_pos2: tm_pos2, tm_pos3: tm_pos3,
          tm_price: price, number: number, birth_date: birth_date, height: height,
          club_joined_on: club_joined_on, contract_until: contract_until, loan: loan
        }
      end

      def first_name
        parts = normalized_name.split
        parts.length > 1 ? parts[0..-2].join(' ') : nil
      end

      def last_name
        normalized_name.split.last
      end

      def normalized_name
        @normalized_name ||= I18n.transliterate(data['name'].to_s)
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

        @club ||= Club.for_tm_id(tm_club_id)
      end

      def tm_club_id
        current_assignment&.dig('clubId')&.to_s
      end

      def current_assignment
        @current_assignment ||= Array(data['clubAssignments']).find { |a| a['type'] == 'current' }
      end

      def loan
        current_assignment&.dig('onLoan') == true
      end

      def club_joined_on
        raw = current_assignment&.dig('start')
        Date.parse(raw).iso8601 if raw
      rescue Date::Error
        nil
      end

      def contract_until
        raw = data.dig('attributes', 'contractUntil')
        Date.parse(raw).iso8601 if raw
      rescue Date::Error
        nil
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

        result = JSON.parse(execute_with_retry(label: "tm_id=#{tm_id}").body)['data']
        write_cache(result)
        result
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
