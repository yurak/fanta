module Players
  module Transfermarkt
    class Parser < ApplicationService
      THOUSAND = 1000

      attr_reader :tm_id

      def initialize(tm_id)
        @tm_id = tm_id
      end

      def call
        return false unless tm_id
        return false if Player.find_by(tm_id: tm_id)

        {
          first_name: first_name, last_name: last_name, country: country_code, club_id: club&.id, club_name: club&.name,
          pos1: pos1, pos2: pos2, pos3: pos3, player_url: player_url, tm_pos1: tm_pos1, tm_pos2: tm_pos2, tm_pos3: tm_pos3,
          price: price, number: number, birth_date: birth_date, height: height
        }
      end

      private

      def name_data
        html_page.css('.data-header__headline-wrapper').children
      end

      def first_name
        name_data[1]&.text&.strip&.tr('#', '').to_i.positive? ? name_data[2]&.text&.strip : name_data[0]&.text&.strip
      end

      def last_name
        name_data[1]&.text&.strip&.tr('#', '').to_i.positive? ? name_data[3]&.text&.strip : name_data[1]&.text&.strip
      end

      def country_code
        country_name = html_page.css('.data-header__items .data-header__content .flaggenrahmen')[0].attributes['title'].value
        ISO3166::Country.find_country_by_iso_short_name(country_name)&.alpha2&.downcase
      end

      def club
        @club ||= Club.find_by(tm_name: tm_club_name) || Club.where('reserve_clubs LIKE ?', "%#{tm_club_name}%").first
      end

      def tm_club_name
        html_page.css('.data-header__club').children[1]&.text || html_page.css('.data-header__club').children[0]&.text&.strip
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
        Players::Transfermarkt::PositionMapper.call(Player.new(tm_id: tm_id), 2023)
      end

      def pos1
        Position::HUMAN_MAP[position_arr[0]] if position_arr[0]
      end

      def pos2
        position_arr[1] ? Position::HUMAN_MAP[position_arr[1]] : nil
      end

      def pos3
        position_arr[2] ? Position::HUMAN_MAP[position_arr[2]] : nil
      end

      def birth_date
        html_page.css('.data-header__info-box .data-header__details').children[1].children[1].children[1].children.text.strip[0..11]
      end

      def number
        html_page.css('.data-header__shirt-number').text.strip.tr('#', '')
      end

      def height
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
        @html_page ||= Nokogiri::HTML(request)
      end

      def request
        @request ||= RestClient::Request.execute(
          method: :get, url: player_url, headers: { 'User-Agent': 'product/version' }, verify_ssl: false
        )
      end

      def player_url
        "#{Player::TM_PATH}#{tm_id}"
      end
    end
  end
end
