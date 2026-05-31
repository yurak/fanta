module Leagues
  class FantaActivator < ApplicationService
    def initialize(league_id)
      @league_id = league_id
    end

    def call
      return false unless league&.initial?

      League.transaction do
        create_results
        create_tours
        league.active!
      end
    end

    private

    def league
      return @league if defined?(@league)

      @league = League.find_by(id: @league_id)
    end

    def create_results
      Results::Creator.call(league.id)
    end

    def create_tours
      tournament_rounds.first(tours_number).each_with_index do |round, index|
        Tour.create!(number: index + 1, league: league, tournament_round: round)
      end
    end

    def tournament_rounds
      @tournament_rounds ||= league.tournament.tournament_rounds
                                   .by_season(league.season_id)
                                   .order(:number)
    end

    def tours_number
      tournament_rounds.size - league.tour_difference
    end
  end
end
