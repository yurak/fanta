module WeeklyTeams
  class CapOptimizer
    MAX_PASSES = 100

    State = Struct.new(:slots, :ranked, :used, :counts, :result, keyword_init: true)

    def initialize(state:, cap:, flop:, key_for:)
      @state   = state
      @cap     = cap
      @flop    = flop
      @key_for = key_for
    end

    def call
      MAX_PASSES.times { break unless improve_pass }
    end

    private

    attr_reader :state, :cap

    delegate :slots, :ranked, :used, :counts, :result, to: :state

    def improve_pass
      ranked.each do |candidate|
        next if used.include?(candidate[:player].id)

        slots.each do |slot|
          next unless eligible?(slot, candidate)
          return true if direct_upgrade(slot, candidate) || cap_swap(slot, candidate)
        end
      end

      false
    end

    def eligible?(slot, entry)
      (entry[:player].position_names & slot.positions).any?
    end

    def key_for(entry)
      @key_for.call(entry)
    end

    def direct_upgrade(slot, candidate)
      occupant = result[slot.number]
      return false unless better?(candidate, occupant)

      key = key_for(candidate)
      freed = occupant && key_for(occupant) == key ? 1 : 0
      return false if key && counts[key] - freed >= cap

      replace(slot.number, occupant, candidate)
      true
    end

    def cap_swap(slot, candidate)
      key = key_for(candidate)
      occupant = result[slot.number]
      return false unless key && counts[key] >= cap
      return false if occupant && key_for(occupant) == key
      return false unless better?(candidate, occupant)

      teammates_weak_first(slot, key).any? do |weak_number, weak|
        apply_swap(slot, candidate, occupant, weak_number, weak)
      end
    end

    def apply_swap(slot, candidate, occupant, weak_number, weak)
      weak_slot = slots.find { |s| s.number == weak_number }
      alternative = swap_alternative(weak_slot, candidate, occupant, weak)
      return false unless alternative
      return false unless swap_gain(candidate, occupant, alternative, weak).positive?

      replace(weak_number, weak, alternative)
      replace(slot.number, occupant, candidate)
      true
    end

    def teammates_weak_first(slot, key)
      result.select { |number, entry| entry && number != slot.number && key_for(entry) == key }
            .sort_by { |_, entry| signed_total(entry) }
    end

    def swap_alternative(weak_slot, candidate, occupant, weak)
      ranked.find do |alt|
        next false if used.include?(alt[:player].id) || alt == candidate
        next false unless eligible?(weak_slot, alt)

        room_for?(alt, candidate, occupant, weak)
      end
    end

    def room_for?(alt, candidate, occupant, weak)
      alt_key = key_for(alt)
      return true if alt_key.blank?

      freed = [weak, occupant].compact.count { |entry| key_for(entry) == alt_key }
      added = key_for(candidate) == alt_key ? 1 : 0
      counts[alt_key] - freed + added < cap
    end

    def swap_gain(candidate, occupant, alternative, weak)
      base = occupant ? signed_total(candidate) - signed_total(occupant) : Float::INFINITY
      base + signed_total(alternative) - signed_total(weak)
    end

    def replace(slot_number, old_entry, new_entry)
      remove(old_entry) if old_entry

      used << new_entry[:player].id
      new_key = key_for(new_entry)
      counts[new_key] += 1 if new_key
      result[slot_number] = new_entry
    end

    def remove(entry)
      used.delete(entry[:player].id)
      key = key_for(entry)
      counts[key] -= 1 if key
    end

    def better?(candidate, occupant)
      return true if occupant.nil?

      signed_total(candidate) > signed_total(occupant)
    end

    def signed_total(entry)
      @flop ? -entry[:total] : entry[:total]
    end
  end
end
