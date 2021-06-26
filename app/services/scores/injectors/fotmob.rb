module Scores
  module Injectors
    class Fotmob < ApplicationService
      attr_reader :tournament_round

      def initialize(tournament_round:)
        @tournament_round = tournament_round
      end

      def call
        matches.each do |tm|
          next if tm.source_match_id.empty?

          inject_match_scores(tm)
        end
      end

      private

      def matches
        tournament_round.tournament.national? ? tournament_round.national_matches : tournament_round.tournament_matches
      end

      def inject_match_scores(tournament_match)
        Scores::Injectors::FotmobMatch.call(match: tournament_match)
      end
    end
  end
end
