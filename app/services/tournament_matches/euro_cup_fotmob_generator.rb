module TournamentMatches
  class EuroCupFotmobGenerator < FotmobGenerator
    def call
      t_round_number = 0
      date = Date.current

      matches_data.each do |match_data|
        match_date = match_data['status']['utcTime'].to_date
        next if match_date < Date.current

        t_round_number += 1 if match_date > date
        date = match_date

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

    def matches_data
      TournamentRounds::FotmobParser.call(tournament)
    end
  end
end
