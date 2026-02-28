module TournamentRounds
  class AutoCloser < ApplicationService
    attr_reader :tournament_round

    def initialize(tournament_round_id)
      @tournament_round = TournamentRound.find_by(id: tournament_round_id)
    end

    def call
      return false unless tournament_round

      tournament_round.update(moderated_at: Time.zone.now)
      tournament_round.tours.each do |tour|
        Notifications::Creator.call(notifiable: tour, kind: :tour_moderated)
      end
    end
  end
end
