module Players
  module Transfermarkt
    class PositionParser < ApplicationService
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
        mantra_hash = {}
        positions_hash.each do |tm_pos, number|
          mantra_pos = Position::TM_POSITION_MAP[tm_pos]
          mantra_hash[mantra_pos] = mantra_hash[mantra_pos].to_i + number
        end
        mantra_hash
      end

      def positions_hash
        positions_hash = {}

        position_items.each do |item|
          data = item.children[1].children[1].children[1].children
          number = data[0].text.strip.to_i
          pos_name = data[1].children[0].text
          positions_hash[pos_name] = number
        end

        positions_hash
      end

      def position_items
        html_page.css('.zahl-anzeige')
      end

      def html_page
        @html_page ||= Nokogiri::HTML(html)
      end

      def html
        @html ||= Players::Transfermarkt::BrowserClient.new.fetch_html(
          player.tm_position_path(year),
          headless: tm_headless?,
          cache_key: cache_key,
          ttl: 7 * 86_400
        )
      end

      def cache_key
        "positions_#{player.tm_id}_#{year}"
      end

      def tm_headless?
        ENV.fetch('TM_HEADLESS', 'true') == 'true'
      end
    end
  end
end
