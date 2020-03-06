module Scores
  module Injectors
    class Epl < ApplicationService
      attr_reader :tour

      def initialize(tour: nil)
        @tour = tour
      end

      def call
        raise NotImplementedError, 'Please implement scores injector for EPL'
      end
    end
  end
end
