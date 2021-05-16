module TournamentMatches
  class EuroFotmobGenerator < FotmobGenerator
    def call
      t_round_index = 0
      matches_data.each do |round_data|
        round_data[1].each do |day_data|
          round = tournament_rounds[t_round_index]

          day_data[1].each do |match_data|
            if find_match(match_data['id'])
              update_match(find_match(match_data['id']), match_data)
            else
              create_match(round, match_data)
            end
          end
          t_round_index += 1
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
      TournamentRounds::FotmobParser.call(tournament_url: tournament.source_calendar_url)
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
        time: match_data['status']['startTimeStr'],
        date: match_data['status']['startDateStr']
      )
    end

    def national_team(name)
      team = NationalTeam.find_by(name: name)

      team || NationalTeam.find_by(name: 'Undefined')
    end
  end
end
