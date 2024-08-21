module Scores
  module Injectors
    class Sofascore < BaseSource
      private

      def inject_match_scores(tournament_match)
        Scores::Injectors::SofascoreMatch.call(tournament_match)
      end
    end
  end
end
