module WeeklyTeams
  class SeasonAvgBuilder < ApplicationService
    MIN_APPEARANCES_PCT = 0.5
    include Assignable

    def initialize(tournament_id, season_id)
      @tournament_id = tournament_id
      @season_id     = season_id
    end

    def call
      scores = aggregate_scores
      return [] if scores.empty?

      TeamModule.includes(:slots).order(:name).map do |mod|
        [mod, assign(mod, scores)]
      end
    end

    private

    def aggregate_scores
      round_ids = season_round_ids
      return {} if round_ids.empty?

      min_appearances = (round_ids.size * MIN_APPEARANCES_PCT).ceil

      rps_by_player(round_ids).each_with_object({}) do |(_, rps), hash|
        next if rps.size < min_appearances

        build_entry(hash, rps)
      end
    end

    def season_round_ids
      TournamentRound
        .by_tournament(@tournament_id)
        .by_season(@season_id)
        .pluck(:id)
    end

    def rps_by_player(round_ids)
      RoundPlayer
        .where(tournament_round_id: round_ids)
        .where('score > 0')
        .includes(player: [:positions, { club: :tournament }])
        .group_by(&:player_id)
    end

    def build_entry(hash, rps)
      result_scores = rps.map(&:result_score)
      avg           = (result_scores.sum / result_scores.size.to_f).round(2)
      best_rp       = rps.max_by(&:result_score)

      hash[best_rp.player_id] = {
        player: best_rp.player,
        round_player: best_rp,
        total: avg,
        appearances: rps.size
      }
    end

    def rank(scores)
      scores.values.sort_by { |h| -h[:total] }
    end
  end
end
