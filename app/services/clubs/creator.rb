module Clubs
  class Creator < ApplicationService
    def call
      tournaments.each do |tournament_code, clubs|
        tournament = Tournament.find_by(code: tournament_code)

        next unless tournament

        clubs.each do |code, name|
          club = find_club(code, name)

          if tournament.eurocup
            if club
              club.update(ec_tournament: tournament)
            else
              Club.create(code: code, name: name, ec_tournament: tournament)
            end
          else
            Club.create(code: code, name: name, tournament: tournament) unless club
          end
        end
      end
    end

    private

    def find_club(code, name)
      Club.find_by(code: code) || Club.find_by(name: name)
    end

    def tournaments
      YAML.load_file(Rails.root.join('config/mantra/clubs.yml'))
    end
  end
end
