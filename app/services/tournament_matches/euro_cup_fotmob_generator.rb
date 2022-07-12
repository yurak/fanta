module TournamentMatches
  class EuroCupFotmobGenerator < FotmobGenerator
    def call
      t_round_index = 0
      matches_data.each do |round_data|
        round_data[1].each do |day_data|
          next if day_data[0].to_date < DateTime.current

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

    def matches_data
      TournamentRounds::FotmobParser.call(tournament.source_calendar_url)
    end
  end
end
