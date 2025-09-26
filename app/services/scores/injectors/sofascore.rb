module Scores
  module Injectors
    class Sofascore < BaseSource
      def call
        matches.each do |tm|
          next if tm.base_data.blank? || tm.lineups_data.blank?

          inject_match_scores(tm)
        end
      end

      private

      def inject_match_scores(tournament_match)
        Scores::Injectors::SofascoreMatch.call(tournament_match)
      end
    end
  end
end
