module RoundPlayers
  class Creator < ApplicationService
    attr_reader :tournament_round_id

    def initialize(tournament_round_id)
      @tournament_round_id = tournament_round_id
    end

    def call
      return false unless tournament_round

      tournament_players.each do |player|
        RoundPlayer.find_or_create_by(tournament_round: tournament_round, player: player)
      end
    end

    private

    def tournament_round
      TournamentRound.find_by(id: tournament_round_id)
    end

    def tournament_players
      Player.by_tournament(tournament_round.tournament.id)
    end
  end
end
