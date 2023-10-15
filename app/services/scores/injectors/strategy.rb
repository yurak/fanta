# frozen_string_literal: true

module Scores
  module Injectors
    class Strategy < ApplicationService
      attr_reader :tour

      GERMANY = 'germany'
      ITALY = 'italy'
      EUROPE_CL = 'europe'
      ENGLAND = 'england'
      EURO = 'euro'
      SPAIN = 'spain'
      FRANCE = 'france'

      def initialize(tour)
        @tour = tour
      end

      def call
        case tournament_code
        when ITALY then Calcio
        when GERMANY, EUROPE_CL, ENGLAND, EURO, SPAIN, FRANCE then Fotmob
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
