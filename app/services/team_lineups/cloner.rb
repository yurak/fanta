module TeamLineups
  class Cloner
    attr_reader :old_lineup, :tour, :lineup

    def initialize(old_lineup:, tour:)
      @old_lineup = old_lineup
      @tour = tour
      @lineup = @old_lineup.dup
    end

    def call
      lineup.tour = tour
      old_lineup.match_players.limit(Lineup::MAX_PLAYERS).each do |old_mp|
        new_round_player = RoundPlayer.find_or_create_by(tournament_round: tournament_round, player: old_mp.round_player.player)
        MatchPlayer.create(lineup: lineup, real_position: old_mp.real_position, round_player: new_round_player)
      end
    end

    private

    def tournament_round
      tour.tournament_round
    end
  end
end
