module Lineups
  class Cloner < ApplicationService
    attr_reader :team, :tour

    def initialize(team, tour)
      @team = team
      @tour = tour
    end

    def call
      return false if another_league? || tour_lineup_exists?

      lineup.update(tour: tour, final_score: 0, final_goals: nil)
      old_lineup.match_players.limit(Lineup::MAX_PLAYERS).each do |old_mp|
        MatchPlayer.create(lineup: lineup, real_position: old_mp.real_position, round_player: new_round_player(old_mp))
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

    def new_round_player(match_player)
      RoundPlayer.find_or_create_by(tournament_round: tournament_round, player: player(match_player), club: player(match_player)&.club)
    end

    def player(match_player)
      player = match_player.player

      player = match_player.main_subs.first.reserve_mp.player if match_player.main_subs.any?
      player = match_player.reserve_subs.first.main_mp.player if match_player.reserve_subs.any?

      player
    end
  end
end
