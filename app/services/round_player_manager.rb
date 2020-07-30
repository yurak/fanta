class RoundPlayerManager < ApplicationService
  attr_reader :tournament_round

  def initialize(tournament_round: nil)
    @tournament_round = tournament_round
  end

  def call
    tournament_players.each do |player|
      RoundPlayer.find_or_create_by(tournament_round: tournament_round, player: player)
    end
  end

  private

  def tournament_players
    Player.with_team.by_tournament(tournament_round.tournament.id)
  end
end
