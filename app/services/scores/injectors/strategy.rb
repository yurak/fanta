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
        case tournament_code
        when CALCIO then Calcio
        when EPL, BUNDES then Fotmob
        else Fake
        end
      end

      private

      def tournament_code
        tour.league.tournament.code
      end
    end
  end
end
