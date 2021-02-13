module Scores
  module Injectors
    class Bundes < ApplicationService
      BUNDES_SCORES_URL = 'https://www.fotmob.com/matchDetails?matchId='.freeze

      attr_reader :tournament_round

      def initialize(tournament_round:)
        @tournament_round = tournament_round
      end

      def call
        tournament_round.tournament_matches.each do |tm|
          next if tm.source_match_id.empty?

          inject_match_scores(tm)
        end
      end

      private

      def inject_match_scores(tournament_match)
        Scores::Injectors::FotmobMatch.call(
          match: tournament_match,
          match_url: tournament_match_url(tournament_match.source_match_id)
        )
      end

      def tournament_match_url(match_id)
        "#{BUNDES_SCORES_URL}#{match_id}"
      end
    end
  end
end
