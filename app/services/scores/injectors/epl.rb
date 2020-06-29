module Scores
  module Injectors
    class Epl < ApplicationService
      attr_reader :tour

      def initialize(tour: nil)
        @tour = tour
      end

      def call
        # TODO: implement scores injector for EPL
        # raise NotImplementedError
      end
    end
  end
end
