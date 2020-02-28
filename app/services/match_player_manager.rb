class MatchPlayerManager
  attr_reader :tour

  def initialize(tour: nil)
    @tour = tour
  end

  def create
    tour.lineups.each do |l|
      l.team.players.each do |p|
        next if MatchPlayer.where(player_id: p.id, lineup_id: l.id).any?

        MatchPlayer.create(player_id: p.id, lineup_id: l.id, subs_status: :not_in_squad)
      end
    end
  end
end
