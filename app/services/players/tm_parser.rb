module Players
  class TmParser < ApplicationService
    THOUSAND = 1000

    def initialize(player)
      @player = player
    end

    def call
      return false unless @player&.tm_id

      @player.update(
        birth_date: birth_date,
        height: height,
        number: number,
        tm_price: tm_price
      )
    end

    private

    def number
      html_page.css('.data-header__shirt-number').text.strip.tr('#', '')
    end

    def birth_date
      html_page.css('.data-header__info-box .data-header__details').children[1].children[1].children[1].children.text.strip[0..11]
    end

    def height
      html_page.css('.data-header__info-box .data-header__details').children[3].children[1].children[1].children.text[0..3].tr(',', '')
    end

    def tm_price
      return 0 if html_page.css('.data-header__market-value-wrapper').blank?

      multiplier = case html_page.css('.data-header__market-value-wrapper').children[2].text
                   when 'm' then THOUSAND * THOUSAND
                   when 'k' then THOUSAND
                   else 1
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
      @request ||= RestClient.get(@player.tm_path)
    end
  end
end
