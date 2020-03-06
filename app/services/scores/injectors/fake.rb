module Scores
  module Injectors
    class Fake < ApplicationService
      attr_reader :tour

      def initialize(tour: nil)
        @tour = tour
      end

      def call
        raise NotImplementedError, 'This league is not supported'
      end
    end
  end
end
