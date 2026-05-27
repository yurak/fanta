module WeeklyTeams
  module Assignable
    private

    def assign(mod, scores)
      ranked = rank(scores)
      used   = Set.new
      slots  = mod.slots.sort_by(&:number)
      result = fill_slots(slots, ranked, used)
      slots.map { |s| { slot: s, entry: result[s.number] } }
    end

    def fill_slots(slots, ranked, used)
      pending = slots.dup
      result  = {}

      until pending.empty?
        candidates = pending.map { |s| [s, eligible(s, ranked, used)] }
        slot, picks = candidates.min_by { |_, e| e.size }
        pending.delete(slot)

        pick = picks.first
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
  end
end
