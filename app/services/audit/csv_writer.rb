module Audit
  class CsvWriter < ApplicationService
    attr_reader :players, :t_match

    def initialize(t_match, players)
      @t_match = t_match
      @players = players
    end

    def call
      CSV.open('log/missed_players.csv', 'ab') do |writer|
        writer << ["===== #{DateTime.now.strftime('%^a, %^b %e, %H:%M')} ==== #{tournament.name} ==== ##{t_match.tournament_round.id} "]

        players.each do |player_record|
          writer << [player_record[1]]
        end
      end
    end

    private

    def tournament
      @tournament ||= t_match.tournament_round.tournament
    end
  end
end
