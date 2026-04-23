module TeamOfWeek
  class Builder < ApplicationService
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

          s = rp.result_score
          if flop?
            entry = (hash[rp.player_id] ||= { player: rp.player, total: Float::INFINITY })
            entry[:total] = [entry[:total], s].min
          else
            next unless s.positive?

            entry = (hash[rp.player_id] ||= { player: rp.player, total: 0.0 })
            entry[:total] = [entry[:total], s].max
          end
        end
    end

    def assign(mod, scores)
      ranked  = rank(scores)
      used    = Set.new
      slots   = mod.slots.sort_by(&:number)
      result  = fill_slots(slots, ranked, used)
      slots.map { |s| { slot: s, entry: result[s.number] } }
    end

    def rank(scores)
      return scores.values.sort_by { |h| h[:total] } if flop?

      scores.values.sort_by { |h| -h[:total] }
    end

    def fill_slots(slots, ranked, used)
      pending = slots.dup
      result  = {}

      until pending.empty?
        slot = pending.min_by { |s| eligible(s, ranked, used).size }
        pending.delete(slot)

        pick = eligible(slot, ranked, used).first
        next unless pick

        used << pick[:player].id
        result[slot.number] = pick
      end

      result
    end

    def eligible(slot, ranked, used)
      pos = slot.positions
      ranked.reject { |h| used.include?(h[:player].id) }
            .select { |h| (h[:player].position_names & pos).any? }
    end

    def exclude?(round_player)
      round_player.score.zero?
    end

    def flop?
      @mode == :flop
    end
  end
end
