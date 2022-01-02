module Audit
  class CsvWriter < ApplicationService
    attr_reader :host_players, :guest_players, :t_match

    def initialize(t_match, host_players, guest_players)
      @t_match = t_match
      @host_players = host_players
      @guest_players = guest_players
    end

    def call
      CSV.open('log/missed_players.csv', 'ab') do |writer|
        host_players.each do |player_record|
          writer << [DateTime.now, tournament, t_match.tournament_round.number, t_match.host_club.name, t_match.id, player_record]
        end
        guest_players.each do |player_record|
          writer << [DateTime.now, tournament, t_match.tournament_round.number, t_match.guest_club.name, t_match.id, player_record]
        end
      end
    end

    private

    def tournament
      @tournament ||= t_match.tournament_round.tournament.name
    end
  end
end
