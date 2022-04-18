module RoundPlayers
  class Updater < ApplicationService
    attr_reader :tournament_round

    def initialize(tournament_round)
      @tournament_round = tournament_round
    end

    def call
      return false unless round_players.present? && tournament_round.finished?

      round_players.with_score.without_final_score.each do |round_player|
        round_player.update(final_score: round_player.result_score)
      end
    end

    private

    def round_players
      @round_players ||= tournament_round&.round_players
    end
  end
end
