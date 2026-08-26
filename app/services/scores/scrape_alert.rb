module Scores
  class ScrapeAlert < ApplicationService
    def initialize(candidates:, with_data:, failures:, tournaments:)
      @candidates = candidates
      @with_data = with_data
      @failures = failures
      @tournaments = tournaments
    end

    def call
      return unless @failures.positive? && @with_data.zero?

      Rollbar.warning('[live-scores] FotMob scrape failing for all live matches',
                      candidates: @candidates, failures: @failures, tournaments: @tournaments)
    end
  end
end
