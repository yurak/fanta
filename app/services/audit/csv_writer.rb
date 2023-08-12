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
        if host_players.any? || guest_players.any?
          writer << ["==== #{DateTime.now.strftime('%^a, %^b %e, %H:%M')} ==== #{tournament.name} ==== ##{t_match.tournament_round.id} "]

          if tournament.national_teams.any?
            write_national_data(writer)
          else
            write_club_data(writer)
          end
        end
      end
    end

    private

    def write_club_data(writer)
      host_players.each do |player_record|
        writer << [t_match.host_club.name, '---', player_record]
      end
      guest_players.each do |player_record|
        writer << [t_match.guest_club.name, '---', player_record]
      end
    end

    def write_national_data(writer)
      host_players.each do |player_record|
        writer << [t_match.host_team.name, t_match.id, player_record]
      end
      guest_players.each do |player_record|
        writer << [t_match.guest_team.name, t_match.id, player_record]
      end
    end

    def tournament
      @tournament ||= t_match.tournament_round.tournament
    end
  end
end
