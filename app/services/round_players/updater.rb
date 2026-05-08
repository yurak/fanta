module RoundPlayers
  class Updater < ApplicationService
    attr_reader :tournament_round

    def initialize(tournament_round)
      @tournament_round = tournament_round
    end

    def call
      return false unless round_players.present? && tournament_round.finished?

      players_to_update = round_players.with_score.without_final_score.to_a
      return false if players_to_update.empty?

      players_to_update.each { |rp| rp.update(final_score: rp.result_score) }
      Stats::Creator.call(player_ids: round_players.pluck(:player_id).uniq)
    end

    private

    def round_players
      @round_players ||= tournament_round&.round_players
    end
  end
end
