module WeeklyTeams
  class Builder < ApplicationService
    include Assignable

    MODES = %i[top flop].freeze

    def initialize(round_ids, mode: :top)
      @round_ids = round_ids
      @mode = MODES.include?(mode) ? mode : :top
    end

    def call
      return [] if @round_ids.blank?

      scores = aggregate_scores
      TeamModule.includes(:slots).order(:name).map do |mod|
        [mod, assign(mod, scores)]
      end
    end

    private

    def aggregate_scores
      RoundPlayer
        .where(tournament_round_id: @round_ids)
        .includes(player: [:positions, { club: :tournament }])
        .each_with_object({}) do |rp, hash|
          next if exclude?(rp)

          update_entry(hash, rp, rp.result_score)
        end
    end

    def update_entry(hash, round_player, score)
      if flop?
        entry = (hash[round_player.player_id] ||= { player: round_player.player, round_player: round_player, total: Float::INFINITY })
        return unless score < entry[:total]
      else
        return unless score.positive?

        entry = (hash[round_player.player_id] ||= { player: round_player.player, round_player: round_player, total: 0.0 })
        return unless score > entry[:total]
      end

      entry[:total] = score
      entry[:round_player] = round_player
    end

    def rank(scores)
      return scores.values.sort_by { |h| h[:total] } if flop?

      scores.values.sort_by { |h| -h[:total] }
    end

    def exclude?(round_player)
      round_player.score.zero?
    end

    def flop?
      @mode == :flop
    end
  end
end
