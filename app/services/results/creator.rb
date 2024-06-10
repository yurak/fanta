module Results
  class Creator < ApplicationService
    def initialize(league_id)
      @league_id = league_id
    end

    def call
      return false if league&.teams.blank?

      league.teams.each do |team|
        Result.find_or_create_by(team: team, league: league)
      end
    end

    private

    def league
      @league ||= League.find_by(id: @league_id)
    end
  end
end
