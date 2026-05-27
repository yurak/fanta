module WeeklyTeams
  SeasonBonuses = Struct.new(
    :player,
    :goals, :scored_penalty, :failed_penalty, :penalties_won,
    :missed_goals, :missed_penalty, :caught_penalty, :saves,
    :assists, :own_goals, :conceded_penalty,
    :yellow_card, :red_card, :cleansheet,
    keyword_init: true
  ) do
    def self.from_round_players(rps) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      new(
        player: rps.first.player,
        goals: rps.sum { |rp| rp.goals.to_i },
        scored_penalty: rps.sum { |rp| rp.scored_penalty.to_i },
        failed_penalty: rps.sum { |rp| rp.failed_penalty.to_i },
        penalties_won: rps.sum { |rp| rp.penalties_won.to_i },
        missed_goals: rps.sum { |rp| rp.missed_goals.to_i },
        missed_penalty: rps.sum { |rp| rp.missed_penalty.to_i },
        caught_penalty: rps.sum { |rp| rp.caught_penalty.to_i },
        saves: rps.sum { |rp| rp.saves.to_i },
        assists: rps.sum { |rp| rp.assists.to_i },
        own_goals: rps.sum { |rp| rp.own_goals.to_i },
        conceded_penalty: rps.sum { |rp| rp.conceded_penalty.to_i },
        yellow_card: rps.count(&:yellow_card),
        red_card: rps.count(&:red_card),
        cleansheet: rps.count(&:cleansheet)
      )
    end
  end
end
