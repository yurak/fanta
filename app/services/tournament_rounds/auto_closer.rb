module TournamentRounds
  class AutoCloser < ApplicationService
    attr_reader :tournament_round, :tournament

    def initialize(tournament_round_id)
      @tournament_round = TournamentRound.find_by(id: tournament_round_id)
    end

    def call
      return false unless tournament_round

      tournament_round.update(moderated_at: Time.zone.now)
      tournament_round.tours.each do |tour|
        TelegramBot::ModeratedTourNotifier.call(tour)
      end
    end
  end
end
