module Lineups
  module BenchKeeper
    module_function

    def ensure_first(bench, pool)
      return bench if bench.empty? || keeper?(bench.first)

      keeper = bench.find { |player| keeper?(player) } || pool.find { |player| keeper?(player) }
      return bench if keeper.nil?

      [keeper, *(bench - [keeper])].first(bench.size)
    end

    def keeper?(player)
      player.position_names.include?(Position::GOALKEEPER)
    end
  end
end
