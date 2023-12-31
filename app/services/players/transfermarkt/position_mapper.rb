module Players
  module Transfermarkt
    class PositionMapper < ApplicationService
      MIN_SEASON_NUMBER = 15
      MIN_DEF_NUMBER = 10
      MIN_POS_NUMBER = 5
      SECOND_COEFFICIENT = 0.3
      LOW_COEFFICIENT = 0.1
      FORWARD = 'FW'.freeze
      STRIKER = 'ST'.freeze
      WING_BACK = 'WB'.freeze
      ATTACK_POS = [FORWARD, STRIKER].freeze
      DEFENCE_POS = %w[CB RB LB].freeze
      FULLBACK_POS = %w[RB LB].freeze
      LOWER_POS_PAIRS = [%w[W WB], %w[W CM], %w[DM CB], %w[CM DM], %w[AM WB], %w[AM CM], %w[FW AM], %w[FW W]].freeze
      VIOLET_LINE_POS = %w[W AM].freeze

      attr_reader :player, :current_year

      def initialize(player, year)
        @player = player
        @current_year = year
      end

      def call
        return false unless player&.tm_id

        prepare_analyzed_data
        return false if mantra_arr.first&.second.to_i < MIN_POS_NUMBER

        @result_arr = [first_pos]
        process_strikers
        return @result_arr if ATTACK_POS.include?(@result_arr.first)

        add_second_pos
        add_wb_to_fullback
        add_def_to_wingback
        remove_lower_pos
        process_am_w

        @result_arr
      end

      private

      def prepare_analyzed_data
        @analyzed_data = if current_stat.values.sum < MIN_SEASON_NUMBER
                           two_seasons_stat
                         else
                           current_stat
                         end
      end

      def process_strikers
        return unless first_pos == STRIKER

        previous_pos = previous_stat.sort_by { |_key, value| value }.reverse.first&.first
        @result_arr = [FORWARD] unless previous_pos == STRIKER
      end

      def add_second_pos
        @result_arr << mantra_arr.second&.first if mantra_arr.second&.second.to_i > (SECOND_COEFFICIENT * sum)
      end

      def add_wb_to_fullback
        @result_arr << WING_BACK if (@result_arr - FULLBACK_POS).empty?
      end

      def add_def_to_wingback
        return unless @result_arr == [WING_BACK]

        DEFENCE_POS.each do |pos|
          @result_arr << pos if two_seasons_stat[pos].to_i > MIN_DEF_NUMBER
        end
      end

      def remove_lower_pos
        @result_arr.pop(1) if LOWER_POS_PAIRS.include?(@result_arr)
      end

      def process_am_w
        return if VIOLET_LINE_POS.exclude?(first_pos)

        matches = @analyzed_data[STRIKER].to_i + @analyzed_data[FORWARD].to_i
        if matches > (SECOND_COEFFICIENT * sum)
          @result_arr = [FORWARD]
        elsif matches > (LOW_COEFFICIENT * sum)
          @result_arr[1] = FORWARD
        end
      end

      def sum
        @sum ||= @analyzed_data.values.sum
      end

      def mantra_arr
        @mantra_arr ||= @analyzed_data.sort_by { |_key, value| value }.reverse
      end

      def first_pos
        @first_pos ||= mantra_arr.first.first
      end

      def current_stat
        @current_stat ||= Players::Transfermarkt::PositionParser.call(player, current_year)
      end

      def previous_stat
        @previous_stat ||= Players::Transfermarkt::PositionParser.call(player, current_year - 1)
      end

      def two_seasons_stat
        @two_seasons_stat ||= current_stat.merge(previous_stat) { |_, cur, prev| cur + prev }
      end
    end
  end
end
