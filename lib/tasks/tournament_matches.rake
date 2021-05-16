namespace :tournament_matches do
  desc 'Create EPL TournamentMatches'
  task generate_epl_matches: :environment do
    tournament = Tournament.find_by(code: Scores::Injectors::Strategy::EPL)
    TournamentMatches::FotmobGenerator.call(tournament: tournament)
  end

  desc 'Create Serie A TournamentMatches'
  task generate_seriea_matches: :environment do
    TournamentMatches::SerieaGenerator.call
  end

  desc 'Create Bundesliga TournamentMatches'
  task generate_bundes_matches: :environment do
    tournament = Tournament.find_by(code: Scores::Injectors::Strategy::BUNDES)
    TournamentMatches::FotmobGenerator.call(tournament: tournament)
  end

  desc 'Create Euro2020 TournamentMatches'
  task generate_euro20_matches: :environment do
    tournament = Tournament.find_by(code: Scores::Injectors::Strategy::EURO)
    TournamentMatches::EuroFotmobGenerator.call(tournament: tournament)
  end
end
