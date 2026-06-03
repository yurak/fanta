module Tours
  class LineupGenerator < ApplicationService
    def initialize(tour)
      @tour = tour
    end

    def call
      return unless tour.locked? && tour.mantra?

      clone_missed_lineups
      generate_not_in_squad_players
      snapshot_player_positions
      tour.update!(lineups_generated: true)
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

    def snapshot_player_positions
      tour.lineups.each do |lineup|
        lineup.match_players.includes(round_player: { player: :positions }).find_each do |mp|
          mp.update_column(:player_positions, mp.round_player.position_names.join('/')) # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end
  end
end
