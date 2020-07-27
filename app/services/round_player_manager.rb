class RoundPlayerManager
  attr_reader :tournament_round

  def initialize(tournament_round: nil)
    @tournament_round = tournament_round
  end

  def create
    # TODO: create RoundPlayers for each Player of tournament
    #
    # tour.lineups.each do |l|
    #   l.team.players.each do |p|
    #     next if MatchPlayer.where(round_player_id: p.id, lineup_id: l.id).any?
    #
    #     MatchPlayer.create(player_id: p.id, lineup_id: l.id, subs_status: :not_in_squad)
    #   end
    # end
  end
end
