# frozen_string_literal: true

module Scores
  module Injectors
    class Strategy
      attr_reader :tour

      CALCIO = 'serie_a'
      EPL = 'epl'
      BUNDES = 'bundesliga'

      def initialize(tour)
        @tour = tour
      end

      def klass
        if tournament_code == CALCIO
          Calcio
        elsif tournament_code == EPL
          Epl
        elsif tournament_code == BUNDES
          Bundes
        else
          Fake
        end
      end

      private

      def tournament_code
        tour.league.tournament.code
      end
    end
  end
end
