# frozen_string_literal: true

module Scores
  module Injectors
    class Strategy
      attr_reader :user

      CALCIO = 'serie_a'
      EPL = 'epl'

      def initialize(user)
        @user = user
      end

      def klass
        if tournament_code == CALCIO
          Calcio
        elsif tournament_code == EPL
          Epl
        else
          Fake
        end
      end

      private

      def tournament_code
        user.league.tournament.code
      end
    end
  end
end
