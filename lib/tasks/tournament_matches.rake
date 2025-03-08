# rubocop:disable Metrics/BlockLength:
namespace :tournament_matches do
  # rake 'tournament_matches:generate_fotmob_matches[1]'
  desc 'Create TournamentMatches from Fotmob'
  task :generate_fotmob_matches, %i[tournament_id] => :environment do |_t, args|
    tournament = Tournament.find(args[:tournament_id])
    TournamentMatches::FotmobGenerator.call(tournament) if tournament
  end

  # rake 'tournament_matches:generate_matches_url[url]'
  desc 'Create TournamentMatches from csv file by url'
  task :generate_matches_url, %i[file_url code] => :environment do |_t, args|
    csv_text = URI.parse(args[:file_url]).open.read
    next unless csv_text

    tournament = Tournament.find_by(code: args[:code])
    next unless tournament

    csv = CSV.parse(csv_text, headers: true)
    csv&.each do |match_data|
      home_club = Club.find_by(name: match_data['home_club']) || Club.find_by(full_name: match_data['home_club'])
      away_club = Club.find_by(name: match_data['away_club']) || Club.find_by(full_name: match_data['away_club'])
      round = tournament.tournament_rounds.by_season(Season.last.id).find_by(number: match_data['round_number'])
      score = match_data['score']&.split('-')

      TournamentMatch.create(
        tournament_round: round,
        host_club: home_club,
        guest_club: away_club,
        host_score: score ? score[0] : nil,
        guest_score: score ? score[1] : nil,
        source_match_id: match_data['fotmob_id'],
        page_url: match_data['page_url'],
        round_name: match_data['round_number'],
        time: DateTime.parse(match_data['date']).utc.in_time_zone('EET').strftime('%H:%M'),
        date: DateTime.parse(match_data['date']).utc.in_time_zone('EET').strftime('%^b %e, %Y')
      )
    end
  end

  # rake 'tournament_matches:update_matches_by_url[url]'
  desc 'Update TournamentMatches from csv file by url'
  task :update_matches_by_url, %i[file_url] => :environment do |_t, args|
    csv_text = URI.parse(args[:file_url]).open.read
    next unless csv_text

    csv = CSV.parse(csv_text, headers: true)
    csv&.each do |match_data|
      match = TournamentMatch.find_by(source_match_id: match_data['fotmob_id'])
      next unless match

      match.update(page_url: match_data['page_url'])
    end
  end

  desc 'Create Italy TournamentMatches'
  task generate_italy_matches: :environment do
    # TournamentMatches::SerieaGenerator.call
  end

  # rake 'tournament_matches:generate_euro20_matches'
  desc 'Create Euro TournamentMatches'
  task generate_euro20_matches: :environment do
    tournament = Tournament.find_by(code: Scores::Injectors::Strategy::EURO)
    return unless tournament

    TournamentMatches::NationalFotmobGenerator.call(tournament)
  end

  desc 'Create WorldCup2022 TournamentMatches'
  task generate_wc_matches: :environment do
    tournament = Tournament.find_by(code: 'world_cup')
    return unless tournament

    TournamentMatches::NationalFotmobGenerator.call(tournament)
  end

  # rake 'tournament_matches:generate_ecl_matches'
  desc 'Create Champions League TournamentMatches for Group stage'
  task generate_ecl_matches: :environment do
    tournament = Tournament.find_by(code: Scores::Injectors::Strategy::EUROPE_CL)
    return unless tournament

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

  # rake 'tournament_matches:generate_matches_list_json'
  desc 'Create csv file with tournament matches from json file'
  task generate_matches_list_json: :environment do
    file = File.open('log/matches.json')

    # response = JSON.load(file)
    response = JSON.parse(file)
    data = response['matches']['allMatches']
    CSV.open('log/matches_list.csv', 'ab') do |writer|
      writer << %w[fotmob_id home_club away_club date score page_url round_number]
      data.each do |match|
        writer << [match['id'], match['home']['name'], match['away']['name'], match['status']['utcTime'], match['status']['scoreStr'],
                   match['pageUrl'], match['roundName']]
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
