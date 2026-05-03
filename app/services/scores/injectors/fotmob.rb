module Scores
  module Injectors
    class Fotmob < BaseSource
      private

      def inject_match_scores(tournament_match)
        Scores::Injectors::FotmobMatch.call(tournament_match)
      end
    end
  end
end
