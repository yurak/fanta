module TeamLineups
  class Cloner < ApplicationService
    attr_reader :team, :tour

    def initialize(team:, tour:)
      @team = team
      @tour = tour
    end

    def call
      return false if another_league? || tour_lineup_exists?

      lineup.tour = tour
      old_lineup.match_players.limit(Lineup::MAX_PLAYERS).each do |old_mp|
        new_round_player = RoundPlayer.find_or_create_by(tournament_round: tournament_round, player: old_mp.round_player.player)
        MatchPlayer.create(lineup: lineup, real_position: old_mp.real_position, round_player: new_round_player)
      end
    end

    private

    def old_lineup
      @old_lineup ||= team.lineups.first
    end

    def another_league?
      old_lineup&.tour&.league != tour.league
    end

    def tour_lineup_exists?
      tour.lineups.exists?(team_id: old_lineup.team_id)
    end

    def lineup
      @lineup ||= old_lineup.dup
    end

    def tournament_round
      tour.tournament_round
    end
  end
end
