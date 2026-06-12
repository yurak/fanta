module WeeklyTeams
  module Assignable
    private

    def assign(mod, scores)
      ranked = rank(scores)
      used   = Set.new
      counts = Hash.new(0)
      slots  = mod.slots.sort_by(&:number)
      result = fill_slots(slots, ranked, used, counts)
      optimize_capped_picks(slots, ranked, used, counts, result)
      slots.map { |s| { slot: s, entry: result[s.number] } }
    end

    def fill_slots(slots, ranked, used, counts)
      pending = slots.dup
      result  = {}

      until pending.empty?
        candidates = pending.map { |s| [s, eligible(s, ranked, used, counts)] }
        slot, picks = candidates.min_by { |_, e| e.size }
        pending.delete(slot)

        pick = picks.first
        next unless pick

        used << pick[:player].id
        count_team_pick(counts, pick)
        result[slot.number] = pick
      end

      result
    end

    def eligible(slot, ranked, used, counts)
      pos = slot.positions
      ranked.reject { |h| used.include?(h[:player].id) || team_capped?(h, counts) }
            .select { |h| (h[:player].position_names & pos).any? }
    end

    def count_team_pick(counts, pick)
      return unless team_cap

      key = team_key(pick)
      counts[key] += 1 if key
    end

    def team_capped?(entry, counts)
      return false unless team_cap

      key = team_key(entry)
      key.present? && counts[key] >= team_cap
    end

    def optimize_capped_picks(slots, ranked, used, counts, result)
      return unless team_cap

      state = CapOptimizer::State.new(slots: slots, ranked: ranked, used: used,
                                      counts: counts, result: result)
      CapOptimizer.new(state: state, cap: team_cap, flop: flop?, key_for: method(:team_key)).call
    end

    def team_cap
      nil
    end

    def team_key(_entry)
      nil
    end

    def flop?
      false
    end
  end
end
