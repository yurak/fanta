namespace :tournament_matches do
  # rake 'tournament_matches:generate_fotmob_matches[1]'
  desc 'Create TournamentMatches from Fotmob'
  task :generate_fotmob_matches, %i[tournament_id] => :environment do |_t, args|
    tournament = Tournament.find(args[:tournament_id])
    TournamentMatches::FotmobGenerator.call(tournament) if tournament
  end

  desc 'Create Serie A TournamentMatches'
  task generate_seriea_matches: :environment do
    # TournamentMatches::SerieaGenerator.call
  end

  desc 'Create Euro2020 TournamentMatches'
  task generate_euro20_matches: :environment do
    tournament = Tournament.find_by(code: Scores::Injectors::Strategy::EURO)
    TournamentMatches::NationalFotmobGenerator.call(tournament)
  end

  desc 'Create WorldCup2022 TournamentMatches'
  task generate_wc_matches: :environment do
    tournament = Tournament.find_by(code: 'world_cup')
    TournamentMatches::NationalFotmobGenerator.call(tournament)
  end

  # rake 'tournament_matches:generate_ecl_matches'
  desc 'Create Champions League TournamentMatches'
  task generate_ecl_matches: :environment do
    tournament = Tournament.find_by(code: Scores::Injectors::Strategy::ECL)
    TournamentMatches::EuroCupFotmobGenerator.call(tournament)
  end
end
