namespace :national_matches do
  # rake 'national_matches:generate_by_url[https://mantrafootball.s3.eu-west-1.amazonaws.com/players_lists/matches_list_wc2026.csv,world_cup]'
  desc 'Create NationalMatches from csv file by url'
  task :generate_by_url, %i[file_url code] => :environment do |_t, args|
    csv_text = URI.parse(args[:file_url]).open.read
    next unless csv_text

    tournament = Tournament.find_by(code: args[:code])
    next unless tournament

    csv = CSV.parse(csv_text, headers: true)
    csv.each do |match_data|
      host_team = NationalTeam.find_by(name: match_data['home_club'])
      guest_team = NationalTeam.find_by(name: match_data['away_club'])
      round = tournament.tournament_rounds.by_season(Season.last.id).find_by(number: match_data['round_number'])
      score = match_data['score']&.split('-')

      NationalMatch.create(
        tournament_round: round,
        host_team: host_team,
        guest_team: guest_team,
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
end
