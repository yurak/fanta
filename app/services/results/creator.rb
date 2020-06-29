module Results
  class Creator < ApplicationService
    def initialize(league_id)
      @league_id = league_id
    end

    def call
      return unless league

      league.teams.each do |team|
        Result.create(team_id: team.id)
      end
    end

    private

    def league
      @league ||= League.find_by(id: @league_id)
    end
  end
end
