module TournamentMatches
  class NationalFotmobGenerator < FotmobGenerator
    def call
      t_round_number = 0
      t_round_data = nil

      matches_data.each do |match_data|
        unless t_round_data == match_data['status']['utcTime'][0...10]
          t_round_data = match_data['status']['utcTime'][0...10]
          t_round_number += 1
        end

        if find_match(match_data['id'])
          update_match(find_match(match_data['id']), match_data)
        else
          round = TournamentRound.find_by(season: season, tournament: tournament, number: t_round_number)
          next unless round

          create_match(round, match_data)
        end
      end
    end

    private

    def update_match(match, match_data)
      match.update(
        source_match_id: match_data['id'],
        host_team: national_team(match_data['home']['name']),
        guest_team: national_team(match_data['away']['name']),
        host_score: result(match_data)[0],
        guest_score: result(match_data)[1]
      )
    end

    def result(match_data)
      return [] unless match_data['status']['started'] && match_data['status']['finished']

      match_data['status']['scoreStr'].split(' - ')
    end

    def matches_data
      TournamentRounds::FotmobParser.call(tournament)
    end

    def find_match(source_match_id)
      NationalMatch.find_by(source_match_id: source_match_id)
    end

    def create_match(round, match_data)
      NationalMatch.create(
        tournament_round: round,
        host_team: national_team(match_data['home']['name']),
        guest_team: national_team(match_data['away']['name']),
        source_match_id: match_data['id'],
        round_name: match_data['roundName'],
        time: DateTime.parse(match_data['status']['utcTime']).utc.in_time_zone('EET').strftime('%H:%M'),
        date: DateTime.parse(match_data['status']['utcTime']).utc.in_time_zone('EET').strftime('%^b %e, %Y')
      )
    end

    def national_team(name)
      team = NationalTeam.find_by(name: name)

      team || NationalTeam.find_by(name: 'Undefined')
    end
  end
end
