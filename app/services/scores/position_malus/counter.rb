module Scores
  module PositionMalus
    class Counter < ApplicationService
      def initialize(real_position, player_positions)
        @real_position = real_position
        @player_positions = player_positions
      end

      def call
        return if native_position?

        malus = Position::L_MALUS
        real_positions_arr.each do |real_position|
          @player_positions.each do |position|
            temp_malus = Position::MALUS[real_position][position]
            next unless temp_malus

            malus = temp_malus if temp_malus < malus
          end
        end

        malus
      end

      private

      def real_positions_arr
        @real_position.split('/')
      end

      def native_position?
        (real_positions_arr & @player_positions).present?
      end
    end
  end
end
