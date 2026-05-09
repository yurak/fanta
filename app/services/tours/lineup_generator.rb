module Tours
  class LineupGenerator < ApplicationService
    def initialize(tour)
      @tour = tour
    end

    def call
      return unless tour.locked? && tour.mantra?

      clone_missed_lineups
      generate_not_in_squad_players
    end

    private

    attr_reader :tour

    def clone_missed_lineups
      tour.teams.each do |team|
        next if tour.lineups.by_team(team.id).any?

        Lineups::Cloner.call(team, tour, auto_cloned: true)
      end
    end

    def generate_not_in_squad_players
      tour.lineups.each do |lineup|
        lineup.team.players_not_in(lineup).each do |round_player|
          MatchPlayer.find_or_create_by(lineup: lineup, round_player: round_player, subs_status: :not_in_squad)
        end
      end
    end
  end
end
