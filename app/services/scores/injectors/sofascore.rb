module Scores
  module Injectors
    class Sofascore < BaseSource
      private

      def inject_match_scores(tournament_match)
        # TODO: fix injector
        # Scores::Injectors::SofascoreMatch.call(tournament_match)
      end
    end
  end
end
