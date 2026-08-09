module Players
  module Transfermarkt
    class PlayerHtmlParser < ApplicationService
      include RetriableApi

      USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0'.freeze
      THOUSAND = 1000
      MULTIPLIERS = { 'k' => THOUSAND, 'm' => THOUSAND**2, 'bn' => THOUSAND**3 }.freeze
      MARKET_VALUE_REGEX = /€\s*(?<amount>[\d.]+)\s*(?<unit>bn|m|k)?/i
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
          tm_price: price, number: number, birth_date: birth_date, height: height,
          club_joined_on: club_joined_on, contract_until: contract_until, loan: loan
        }
      end

      private

      def first_name
        parts = normalized_name.split
        parts.length > 1 ? parts[0..-2].join(' ') : nil
      end

      def last_name
        normalized_name.split.last
      end

      def normalized_name
        @normalized_name ||= I18n.transliterate(text_of('.data-header__headline-wrapper').sub(/\A#\d+\s*/, ''))
      end

      def nationality
        country_name = html_page.css('.data-header__items .data-header__content .flaggenrahmen').first&.attr('title')
        return nil if country_name.blank?

        Player::COUNTRY.key(country_name)&.to_s ||
          ISO3166::Country.find_country_by_iso_short_name(country_name)&.alpha2&.downcase
      end

      def birth_date
        raw = info_row('Date of birth')
        return nil if raw.blank?

        value = raw[0, 10]
        Date.strptime(value, '%d/%m/%Y')
        value
      rescue Date::Error
        nil
      end

      def height
        meters = info_row('Height').to_s[/[\d,.]+/].to_s.tr(',', '.').to_f
        return nil unless meters.positive?

        (meters * 100).round
      end

      def price
        match = MARKET_VALUE_REGEX.match(text_of('.data-header__market-value-wrapper'))
        return 0 unless match

        (match[:amount].to_f * MULTIPLIERS.fetch(match[:unit].to_s.downcase, 1)).round
      end

      def number
        value = text_of('.data-header__shirt-number').tr('#', '').to_i
        value.positive? ? value : nil
      end

      def tm_club_name
        @tm_club_name ||= club&.tm_name
      end

      def club
        return nil if tm_club_id.blank?

        @club ||= Club.for_tm_id(tm_club_id)
      end

      def tm_club_id
        @tm_club_id ||= html_page.css('.data-header__club a').first&.attr('href').to_s[%r{/verein/(\d+)}, 1]
      end

      def loan
        info_table.keys.any? { |label| label.match?(/on loan from/i) }
      end

      def club_joined_on
        iso_date(info_row('Joined'))
      end

      def contract_until
        iso_date(info_row('Contract expires'))
      end

      def iso_date(raw)
        return nil if raw.blank?

        Date.strptime(raw[0, 10], '%d/%m/%Y').iso8601
      rescue Date::Error
        nil
      end

      def positions
        @positions ||= html_page.css('.detail-position__position')
      end

      def tm_pos1
        Position::TM_POS[position_text(0)]
      end

      def tm_pos2
        Position::TM_POS[position_text(2)]
      end

      def tm_pos3
        Position::TM_POS[position_text(3)]
      end

      def position_text(index)
        positions[index]&.text&.strip
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

      def info_table
        @info_table ||= html_page.css('.info-table span.info-table__content')
                                 .each_slice(2)
                                 .to_h { |label, value| [clean(label&.text), clean(value&.text)] }
      end

      def info_row(label)
        key = info_table.keys.find { |candidate| candidate.match?(/\A#{Regexp.escape(label)}/i) }
        info_table[key]
      end

      def text_of(selector)
        clean(html_page.css(selector).text)
      end

      def clean(value)
        value.to_s.gsub(/\s+/, ' ').strip
      end

      def html_page
        @html_page ||= Nokogiri::HTML(html)
      end

      def html
        cached = read_cache
        return cached if cached

        body = execute_with_retry(label: "tm_id=#{tm_id}").body
        write_cache(body)
        body
      end

      def api_request
        RestClient::Request.execute(
          method: :get,
          url: tm_url,
          headers: { 'User-Agent' => USER_AGENT },
          verify_ssl: false
        )
      end

      def cache_path
        Rails.root.join('tmp', 'transfermarkt_cache', "player_html_#{tm_id}.html")
      end

      def cache_disabled?
        ENV['TM_SKIP_CACHE'].present?
      end

      def read_cache
        return nil if cache_disabled?
        return nil unless cache_path.exist?
        return nil if (Time.zone.now.to_i - cache_path.mtime.to_i) > CACHE_TTL

        cache_path.read
      end

      def write_cache(body)
        return if cache_disabled?

        FileUtils.mkdir_p(cache_path.dirname)
        cache_path.write(body)
      end
    end
  end
end
