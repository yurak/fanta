namespace :tournament_matches do
  # rake 'tournament_matches:generate_fotmob_matches[1]'
  desc 'Create TournamentMatches from Fotmob'
  task :generate_fotmob_matches, %i[tournament_id] => :environment do |_t, args|
    tournament = Tournament.find(args[:tournament_id])
    TournamentMatches::FotmobGenerator.call(tournament) if tournament
  end

  desc 'Create Italy TournamentMatches'
  task generate_italy_matches: :environment do
    # TournamentMatches::SerieaGenerator.call
  end

  # rake 'tournament_matches:generate_euro20_matches'
  desc 'Create Euro TournamentMatches'
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
  desc 'Create Champions League TournamentMatches for Group stage'
  task generate_ecl_matches: :environment do
    tournament = Tournament.find_by(code: Scores::Injectors::Strategy::EUROPE_CL)
    TournamentMatches::EuroCupFotmobGenerator.call(tournament)
  end

  # rake 'tournament_matches:generate_matches_list[130,2024]'
  desc 'Create csv file with tournament matches'
  task :generate_matches_list, %i[fotmob_id season_year] => :environment do |_t, args|
    url = "https://www.fotmob.com/api/fixtures?id=#{args[:fotmob_id]}&season=#{args[:season_year]}"

    response = JSON.parse(RestClient.get(url))
    CSV.open("log/matches_#{args[:fotmob_id]}.csv", 'ab') do |writer|
      writer << %w[fotmob_id home_club away_club date score]
      response.each do |match|
        writer << [match['id'], match['home']['name'], match['away']['name'], match['status']['utcTime'], match['status']['scoreStr']]
      end
    end
  end
end
