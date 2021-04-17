class TournamentCreator < ApplicationService
  def call
    tournaments.each do |code, name|
      Tournament.create(name: name, code: code)
    end
  end

  private

  def tournaments
    YAML.load_file(Rails.root.join('config/mantra/tournaments.yml'))
  end
end
