module Players
  module Transfermarkt
    class Parser < ApplicationService
      THOUSAND = 1000

      attr_reader :position_skip, :tm_id

      def initialize(tm_id, position_skip: false)
        @tm_id = tm_id
        @position_skip = position_skip
      end

      def call
        return false unless tm_id

        {
          first_name: first_name, name: last_name, nationality: country_code, club_id: club&.id, club_name: club&.name,
          position1: position1, position2: position2, position3: position3, tm_url: tm_url, tm_pos1: tm_pos1,
          tm_pos2: tm_pos2, tm_pos3: tm_pos3, tm_price: price, number: number, birth_date: birth_date, height: height,
          tm_club_name: tm_club_name
        }
      end

      private

      def name_data
        @name_data ||= html_page.css('.data-header__headline-wrapper').children
      end

      def first_name
        name_data[1]&.text&.strip&.tr('#', '').to_i.positive? ? name_data[2]&.text&.strip : name_data[0]&.text&.strip
      end

      def last_name
        name_data[1]&.text&.strip&.tr('#', '').to_i.positive? ? name_data[3]&.text&.strip : name_data[1]&.text&.strip
      end

      def country_code
        country_text = html_page.css('.data-header__items .data-header__content .flaggenrahmen')[0]
        return unless country_text

        country_name = country_text.attributes['title'].value
        Player::COUNTRY.key(country_name).to_s.presence || ISO3166::Country.find_country_by_iso_short_name(country_name)&.alpha2&.downcase
      end

      def club
        @club ||= Club.find_by(tm_name: tm_club_name) || Club.where('reserve_clubs LIKE ?', "%#{tm_club_name}%").first
      end

      def tm_club_name
        @tm_club_name ||= html_page.css('.data-header__club').children[1]&.text || html_page.css('.data-header__club').children[0]&.text&.strip
      end

      def positions
        html_page.css('.detail-position__position')
      end

      def tm_pos1
        Position::TM_POS[positions[0]&.text]
      end

      def tm_pos2
        Position::TM_POS[positions[2]&.text]
      end

      def tm_pos3
        Position::TM_POS[positions[3]&.text]
      end

      def position_arr
        return [] if position_skip

        @position_arr ||= Players::Transfermarkt::PositionMapper.call(Player.new(tm_id: tm_id), Season.last.start_year)
      end

      def position1
        Position::HUMAN_MAP[position_arr[0]] if position_arr[0]
      end

      def position2
        position_arr[1] ? Position::HUMAN_MAP[position_arr[1]] : nil
      end

      def position3
        position_arr[2] ? Position::HUMAN_MAP[position_arr[2]] : nil
      end

      def birth_date
        return if html_page.css('.data-header__info-box .data-header__details').blank?

        html_page.css('.data-header__info-box .data-header__details').children[1].children[1].children[1].children.text.strip[0..9]
      end

      def number
        html_page.css('.data-header__shirt-number').text.strip.tr('#', '')
      end

      def height
        return if html_page.css('.data-header__info-box .data-header__details').blank?

        html_page.css('.data-header__info-box .data-header__details')
                 .children[3].children[1].children[1].children.text.strip[0..3].tr(',', '')
      end

      def price
        return 0 if html_page.css('.data-header__market-value-wrapper').blank?

        multiplier = case html_page.css('.data-header__market-value-wrapper').children[2].text
                     when 'm' then THOUSAND * THOUSAND
                     else THOUSAND
                     end
        multiplier * price_value.to_f
      end

      def price_value
        html_page.css('.data-header__market-value-wrapper').children[1].text
      end

      def html_page
        @html_page ||= Nokogiri::HTML(html)
      end

      def html
        Players::Transfermarkt::BrowserClient.new.fetch_html(
          tm_url,
          headless: tm_headless?,
          cache_key: "player_#{tm_id}",
          ttl: 7 * 86_400
        )
      end

      def tm_headless?
        ENV.fetch('TM_HEADLESS', 'true') == 'true'
      end

      def tm_url
        "#{Player::TM_PATH}#{tm_id}"
      end
    end
  end
end
