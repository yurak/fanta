module Scores
  class ScrapeAlert < ApplicationService
    FAILURE_RATIO = 0.5

    def initialize(candidates:, with_data:, failures:, tournaments:)
      @candidates = candidates
      @with_data = with_data
      @failures = failures
      @tournaments = tournaments
    end

    def call
      return unless alert?

      Rollbar.warning("[live-scores] FotMob scrape failing for #{@failures}/#{@candidates} live matches",
                      candidates: @candidates, with_data: @with_data, failures: @failures, tournaments: @tournaments)
    end

    private

    def alert?
      return false unless @failures.positive?

      @with_data.zero? || @failures >= @candidates * FAILURE_RATIO
    end
  end
end
