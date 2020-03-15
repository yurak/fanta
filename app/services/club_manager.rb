class ClubManager < ApplicationService
  def call
    tournaments.each do |tournament_code, clubs|
      tournament = Tournament.find_by(code: tournament_code)

      clubs.each do |code, name|
        Club.create(code: code, name: name, tournament: tournament) unless club(code, name)
      end
    end
  end

  private

  def club(code, name)
    Club.find_by(code: code) || Club.find_by(name: name)
  end

  def tournaments
    YAML.load_file(Rails.root.join('config', 'mantra', 'clubs.yml'))
  end
end
