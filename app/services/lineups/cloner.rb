module Lineups
  class Cloner < ApplicationService
    attr_reader :auto_cloned, :team, :tour

    def initialize(team, tour, options = {})
      @team = team
      @tour = tour
      @auto_cloned = options.fetch(:auto_cloned, false)
    end

    def call
      return false if old_lineup.nil? || tour_lineup_exists?

      lineup.update(tour: tour, final_score: 0, final_goals: nil, substitutes: nil, creation_type: creation_type)
      clone_main_slots
      clone_bench_slots
    end

    private

    def clone_main_slots
      main_slots.each do |old_mp|
        player = resolve_main_player(old_mp)
        next unless player

        create_match_player(player, old_mp.real_position)
      end
    end

    def clone_bench_slots
      bench_slots.each do |old_mp|
        p = player_from(old_mp)
        player = team_player_ids.include?(p.id) ? p : available_pool.shift
        next unless player

        create_match_player(player, nil)
      end

      bench_vacancies.times do
        player = available_pool.shift
        break unless player

        create_match_player(player, nil)
      end
    end

    def resolve_main_player(old_mp)
      current = player_from(old_mp)
      return current if team_player_ids.include?(current.id)

      find_main_replacement(old_mp.real_position)
    end

    def find_main_replacement(real_position)
      find_zero_malus_from_pool(real_position) ||
        find_zero_malus_from_bench(real_position) ||
        find_min_malus_from_pool(real_position) ||
        find_min_malus_from_bench(real_position) ||
        take_any_from_pool ||
        take_any_from_bench
    end

    def find_zero_malus_from_pool(real_position)
      player = available_pool.find { |p| zero_malus?(p, real_position) }
      available_pool.delete(player)
      player
    end

    def find_zero_malus_from_bench(real_position)
      idx = bench_slots.index do |mp|
        team_player_ids.include?(mp.player.id) && zero_malus?(mp.player, real_position)
      end
      promote_bench_slot(idx)
    end

    def find_min_malus_from_pool(real_position)
      player = available_pool.min_by { |p| malus_value(p, real_position) }
      return nil if player.nil? || malus_value(player, real_position) == Float::INFINITY

      available_pool.delete(player)
      player
    end

    def find_min_malus_from_bench(real_position)
      idx = bench_slots.each_index
                       .select { |i| team_player_ids.include?(bench_slots[i].player.id) }
                       .select { |i| malus_value(bench_slots[i].player, real_position) < Float::INFINITY }
                       .min_by { |i| malus_value(bench_slots[i].player, real_position) }
      promote_bench_slot(idx)
    end

    def take_any_from_pool
      player = available_pool.first
      available_pool.delete(player)
      player
    end

    def take_any_from_bench
      idx = bench_slots.each_index.find { |i| team_player_ids.include?(bench_slots[i].player.id) }
      promote_bench_slot(idx)
    end

    def promote_bench_slot(idx)
      return nil if idx.nil?

      mp = bench_slots.delete_at(idx)
      @bench_vacancies = (@bench_vacancies || 0) + 1
      mp.player
    end

    def bench_vacancies
      @bench_vacancies || 0
    end

    def zero_malus?(player, real_position)
      real_position.split('/').any? { |pos| player.position_names.include?(pos) }
    end

    def malus_value(player, real_position)
      real_position.split('/').flat_map do |slot_pos|
        player.position_names.map { |pos| Position::MALUS.dig(slot_pos, pos) || Float::INFINITY }
      end.min || Float::INFINITY
    end

    def create_match_player(player, real_position)
      MatchPlayer.create(lineup: lineup, real_position: real_position, round_player: build_round_player(player))
    end

    def build_round_player(player)
      RoundPlayer.find_or_create_by(tournament_round: tournament_round, player: player, club: player&.club)
    end

    def main_slots
      @main_slots ||= old_lineup.match_players.main.to_a
    end

    def bench_slots
      @bench_slots ||= old_lineup.match_players.subs_bench.limit(Lineup::MAX_PLAYERS - main_slots.count).to_a
    end

    def available_pool
      @available_pool ||= begin
        old_ids = Set.new((main_slots + bench_slots).map { |mp| player_from(mp).id })
        team.players.reject { |p| old_ids.include?(p.id) }
      end
    end

    def team_player_ids
      @team_player_ids ||= Set.new(team.players.ids)
    end

    def player_from(match_player)
      player = match_player.player
      player = match_player.main_subs.first.reserve_mp.player if match_player.main_subs.any?
      player = match_player.reserve_subs.first.main_mp.player if match_player.reserve_subs.any?
      player
    end

    def old_lineup
      @old_lineup ||= team.lineups.joins(:tour).where(tours: { league: tour.league }).first
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

    def creation_type
      auto_cloned ? :auto_cloned : :copied
    end
  end
end
