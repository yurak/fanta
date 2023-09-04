module TournamentMatches
  class EuroCupFotmobGenerator < FotmobGenerator
    def call
      t_round_number = 1
      t_match_index = 1

      matches_data.each do |match_data|
        next if match_data['status']['utcTime'] < DateTime.current

        if find_match(match_data['id'])
          update_match(find_match(match_data['id']), match_data)
        else
          round = TournamentRound.find_by(season: season, tournament: tournament, number: t_round_number)
          next unless round

          create_match(round, match_data)
        end

        t_round_number += 1 if (t_match_index % 8).zero?
        t_match_index += 1
      end
    end

    private

    def matches_data
      TournamentRounds::FotmobParser.call(tournament)
    end
  end
end
