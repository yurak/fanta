namespace :tournament_matches do
  desc 'Create EPL TournamentMatches'
  task generate_epl_matches: :environment do
    TournamentMatches::EplGenerator.call
  end

  desc 'Create Serie A TournamentMatches'
  task generate_seriea_matches: :environment do
    TournamentMatches::SerieaGenerator.call
  end
end
