module Scores
  module Injectors
    class BaseSource < ApplicationService
      attr_reader :tournament_round

      def initialize(tournament_round)
        @tournament_round = tournament_round
      end

      def call
        matches.each do |tm|
          next if tm.page_url.blank?

          inject_match_scores(tm)
        rescue StandardError => e
          Rollbar.error(e, match_id: tm.id, page_url: tm.page_url, tournament_round_id: tournament_round.id)
          Rails.logger.error("[scores] injector crashed for #{tm.page_url}: #{e.class}: #{e.message}")
        end
      end

      private

      def matches
        tournament_round.matches
      end

      def inject_match_scores(_tournament_match)
        raise NoMethodError, 'This source is not supported'
      end
    end
  end
end
