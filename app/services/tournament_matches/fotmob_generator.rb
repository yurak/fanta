module TournamentMatches
  class FotmobGenerator < ApplicationService
    attr_reader :tournament

    def initialize(tournament)
      @tournament = tournament
    end

    def call
      tournament_rounds.each do |t_round|
        if t_round.tournament_matches.any?
          update_round_matches(t_round)
        else
          create_round_matches(t_round)
        end
      end
    end

    private

    def update_round_matches(t_round)
      round_data(t_round).each do |match_data|
        match = find_match(match_data['id'])

        update_match(match, match_data) if match
      end
    end

    def find_match(source_match_id)
      TournamentMatch.find_by(source_match_id: source_match_id)
    end

    def update_match(match, match_data)
      match.update(
        host_score: result(match_data)[0],
        guest_score: result(match_data)[1]
      )
    end

    def result(match_data)
      return [] unless match_data['status']['started'] && match_data['status']['finished']

      match_data['status']['scoreStr'].split(' - ')
    end

    def create_round_matches(t_round)
      round_data(t_round).each do |match_data|
        create_match(t_round, match_data)
      end
    end

    def round_data(t_round)
      TournamentRounds::FotmobParser.call(tournament, t_round)
    end

    def create_match(round, match_data)
      TournamentMatch.create(
        tournament_round: round,
        host_club: club(match_data['home']['name']),
        guest_club: club(match_data['away']['name']),
        source_match_id: match_data['id'],
        round_name: match_data['roundName'],
        time: DateTime.parse(match_data['status']['utcTime']).utc.in_time_zone('EET').strftime('%H:%M'),
        date: DateTime.parse(match_data['status']['utcTime']).utc.in_time_zone('EET').strftime('%^b %e, %Y')
      )
    end

    def club(name)
      Club.find_by(name: name) || Club.find_by(full_name: name)
    end

    def tournament_rounds
      @tournament_rounds ||= TournamentRound.where(season: season, tournament: tournament)
    end

    def season
      @season ||= Season.last
    end
  end
end
