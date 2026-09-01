module Scores
  module Injectors
    class Fotmob < BaseSource
      private

      def inject_match_scores(tournament_match)
        Scores::Injectors::FotmobMatch.call(tournament_match, budget: budget)
      end

      def budget
        @budget ||= Scores::ScrapeBudget.new
      end
    end
  end
end
