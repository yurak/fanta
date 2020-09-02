module TournamentRounds
  class Creator < ApplicationService
    def initialize(tournament_id, season_id)
      @tournament = Tournament.find(tournament_id)
      @season = Season.find(season_id)
    end

    def call
      return unless @tournament
      return unless @season

      (1..38).each do |round_number|
        TournamentRound.create(tournament: @tournament, season: @season, number: round_number)
      end
    end
  end
end
