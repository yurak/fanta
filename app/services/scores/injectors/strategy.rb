# frozen_string_literal: true

module Scores
  module Injectors
    class Strategy < ApplicationService
      attr_reader :tour

      BUNDES = 'bundesliga'
      CALCIO = 'serie_a'
      EPL = 'epl'
      EURO = 'euro'
      LALIGA = 'laliga'
      LIGUE1 = 'ligue_1'

      def initialize(tour)
        @tour = tour
      end

      def call
        case tournament_code
        when CALCIO then Calcio
        when BUNDES, EPL, EURO, LALIGA, LIGUE1 then Fotmob
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
