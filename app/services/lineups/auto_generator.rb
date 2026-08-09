module Lineups
  class AutoGenerator < ApplicationService
    def initialize(team, tour)
      @team = team
      @tour = tour
    end

    def call
      return false if players.empty? || tour.lineups.exists?(team_id: team.id)

      fit = best_module_fit
      return false unless fit

      build_lineup(*fit)
      true
    end

    private

    attr_reader :team, :tour

    def build_lineup(team_module, assignments)
      lineup = Lineup.create!(team: team, tour: tour, team_module: team_module, creation_type: :auto_cloned)
      slots = team_module.slots.to_a
      used = []

      assignments.each do |slot_index, player_index, _malus|
        player = players[player_index]
        used << player.id
        create_match_player(lineup, player, slots[slot_index].position)
      end

      fill_bench(lineup, assignments.size, used)
    end

    def fill_bench(lineup, main_count, used)
      bench_target = lineup.players_count - main_count
      players.reject { |player| used.include?(player.id) }
             .first(bench_target)
             .each { |player| create_match_player(lineup, player, nil) }
    end

    def create_match_player(lineup, player, real_position)
      round_player = RoundPlayer.find_or_create_by(tournament_round: tour.tournament_round, player: player,
                                                   club: player.club)
      MatchPlayer.create!(lineup: lineup, real_position: real_position, round_player: round_player)
    end

    # The formation whose 11 slots are all fillable with the lowest total malus.
    def best_module_fit
      TeamModule.includes(:slots).filter_map do |team_module|
        slots = team_module.slots.to_a
        assignments, total = Substitutes::TieredMatcher.call(grid_for(slots))
        next unless assignments.size == slots.size

        [team_module, assignments, total]
      end.min_by(&:last)&.first(2)
    end

    def grid_for(slots)
      slots.map do |slot|
        players.map do |player|
          next 'X' unless slot.positions_with_malus.intersect?(player.position_names)

          Scores::PositionMalus::Counter.call(slot.position, player.position_names)
        end
      end
    end

    def players
      @players ||= team.players.includes(:positions).to_a.uniq(&:id)
    end
  end
end
