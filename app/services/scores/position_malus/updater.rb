module Scores
  module PositionMalus
    class Updater < ApplicationService
      def initialize(tour: nil)
        @tour = tour
      end

      def call
        @tour.match_players.main.with_score.each do |mp|
          next unless mp.position_malus?

          mp.update(position_malus: malus(mp)) if mp.score.positive?
        end
      end

      private

      def malus(match_player)
        Scores::PositionMalus::Counter.call(match_player.real_position, match_player.position_names)
      end
    end
  end
end
