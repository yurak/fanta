module Audit
  class CsvWriter < ApplicationService
    attr_reader :players, :t_match

    def initialize(t_match, players)
      @t_match = t_match
      @players = players
    end

    def call
      CSV.open('log/missed_players.csv', 'ab') do |writer|
        header = "==== #{DateTime.now.strftime('%^a, %^b %e, %H:%M')} ==== #{tournament.name} " \
                 "==== ##{t_match.tournament_round.id} ==== #{match_teams}"
        writer << [header]

        players.each do |player_record|
          writer << [player_record[1]]
        end
      end
    end

    private

    def tournament
      @tournament ||= t_match.tournament_round.tournament
    end

    def match_teams
      if t_match.respond_to?(:host_club)
        "#{t_match.host_club.name} vs #{t_match.guest_club.name}"
      else
        "#{t_match.host_team.name} vs #{t_match.guest_team.name}"
      end
    end
  end
end
