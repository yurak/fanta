namespace :tournament_matches do
  # rake 'tournament_matches:generate_matches_url[url,code]'
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
        time: DateTime.parse(match_data['date']).utc.strftime('%H:%M'),
        date: DateTime.parse(match_data['date']).utc.strftime('%^b %e, %Y')
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

  # rake 'tournament_matches:generate_matches_list_json'
  desc 'Create csv file with tournament matches from json file'
  task generate_matches_list_json: :environment do
    response = File.open('log/matches.json') { |file| JSON.parse(file.read) }
    data = response['fixtures']['allMatches']
    CSV.open('log/matches_list.csv', 'ab') do |writer|
      writer << %w[fotmob_id home_club away_club date score page_url round_number]
      data.each do |match|
        writer << [match['id'], match['home']['name'], match['away']['name'], match['status']['utcTime'], match['status']['scoreStr'],
                   match['pageUrl'], match['roundName']]
      end
    end
  end
end
