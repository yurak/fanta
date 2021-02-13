module TournamentMatches
  class BundesGenerator < ApplicationService
    def call
      tournament_rounds.each do |t_round|
        next if t_round.tournament_matches.any?

        round_data(t_round).each do |day_data|
          day_data[1].each do |match_data|
            create_match(t_round, match_data)
          end
        end
      end
    end

    private

    def round_data(t_round)
      TournamentRounds::BundesParser.call(tournament_round: t_round)
    end

    def create_match(round, match_data)
      TournamentMatch.create(
        tournament_round: round,
        host_club: club(match_data['home']['name']),
        guest_club: club(match_data['away']['name']),
        source_match_id: match_data['id']
      )
    end

    def club(name)
      Club.find_by(name: name) || Club.find_by(full_name: name)
    end

    def tournament_rounds
      TournamentRound.where(season: season, tournament: tournament)
    end

    def tournament
      @tournament ||= Tournament.find_by(code: Scores::Injectors::Strategy::BUNDES)
    end

    def season
      @season ||= Season.last
    end
  end
end
