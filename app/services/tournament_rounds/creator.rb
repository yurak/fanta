module TournamentRounds
  class Creator < ApplicationService
    def initialize(tournament_id, season_id, count: 38)
      @tournament = Tournament.find(tournament_id)
      @season = Season.find(season_id)
      @count = count
    end

    def call
      return unless @tournament
      return unless @season

      (1..@count).each do |round_number|
        TournamentRound.create(tournament: @tournament, season: @season, number: round_number)
      end
    end
  end
end
