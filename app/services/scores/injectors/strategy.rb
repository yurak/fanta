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
        if user.league.tournament.code == CALCIO
          Calcio
        elsif user.league.tournament.code == EPL
          Epl
        end
      end
    end
  end
end
