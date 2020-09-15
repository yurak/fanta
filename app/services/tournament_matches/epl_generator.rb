module TournamentMatches
  class EplGenerator < ApplicationService
    def call
      tournament_rounds.each do |t_round|
        round_data = TournamentRounds::EplEventsParser.call(tournament_round: t_round)
        round_data.each do |match_data|
          TournamentMatch.find_or_create_by(
            tournament_round: t_round,
            host_club: club(match_data['home']),
            guest_club: club(match_data['away'])
          )
        end
      end
    end

    private

    def club(name)
      Club.find_by(full_name: name.titleize) || Club.find_by(name: name.titleize)
    end

    def tournament_rounds
      TournamentRound.where(season: season, tournament: tournament)
    end

    def tournament
      @tournament ||= Tournament.find_by(code: Scores::Injectors::Strategy::EPL)
    end

    def season
      @season ||= Season.last
    end
  end
end
