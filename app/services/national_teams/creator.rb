module NationalTeams
  class Creator < ApplicationService
    def call
      tournaments.each do |tournament_code, national_teams|
        tournament = Tournament.find_by(code: tournament_code)

        next unless tournament

        national_teams.each do |code|
          NationalTeam.create(code: code, tournament: tournament) unless national_team(code)
        end
      end
    end

    private

    def national_team(code)
      NationalTeam.find_by(code: code)
    end

    def tournaments
      YAML.load_file(Rails.root.join('config/mantra/national_teams.yml'))
    end
  end
end
