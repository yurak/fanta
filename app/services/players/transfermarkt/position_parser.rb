module Players
  module Transfermarkt
    class PositionParser < ApplicationService
      TM_POSITION_MAP = {
        'GK' => 'GK',
        'LB' => 'LB',
        'RB' => 'RB',
        'CB' => 'CB',
        'SW' => 'CB',
        'RM' => 'WB',
        'LM' => 'WB',
        'DM' => 'DM',
        'CM' => 'CM',
        'RW' => 'W',
        'LW' => 'W',
        'AM' => 'AM',
        'SS' => 'FW',
        'CF' => 'ST'
      }.freeze

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
          mantra_pos = TM_POSITION_MAP[tm_pos]
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
        @html_page ||= Nokogiri::HTML(request)
      end

      def request
        @request ||= RestClient::Request.execute(
          method: :get, url: player.tm_position_path(year), headers: { 'User-Agent': 'product/version' }, verify_ssl: false
        )
      end
    end
  end
end
