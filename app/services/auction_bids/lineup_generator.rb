module AuctionBids
  class LineupGenerator < ApplicationService
    MIN_APPEARANCES = 15

    def initialize(auction_bid)
      @auction_bid = auction_bid
    end

    def call
      return false unless fillable?

      chosen = []
      slots = TeamModule.all.sample.slots.to_a

      auction_bid.player_bids.order(:id).each_with_index do |player_bid, index|
        player = pick_player(slots[index], chosen)
        next unless player

        chosen << player.id
        player_bid.update!(player_id: player.id, price: player.stats_price)
      end

      true
    end

    private

    attr_reader :auction_bid

    def fillable?
      auction_bid.editable? && tournament.present? && eligible_players.any?
    end

    def pick_player(slot, chosen)
      positions = slot&.positions || []
      available = eligible_players.reject { |player| chosen.include?(player.id) }
      positional = available.select { |player| player.position_names.intersect?(positions) }
      return positional.sample if positional.any?

      fallback_player(positions, available, chosen)
    end

    def fallback_player(positions, available, chosen)
      return available.sample unless positions.include?(Position::GOALKEEPER)

      goalkeepers.reject { |player| chosen.include?(player.id) }.sample
    end

    def eligible_players
      @eligible_players ||= Player.by_tournament(tournament)
                                  .where(id: qualified_player_ids)
                                  .where.not(id: owned_player_ids)
                                  .includes(:positions)
                                  .to_a
    end

    def goalkeepers
      @goalkeepers ||= Player.by_tournament(tournament)
                             .by_position(Position::GOALKEEPER)
                             .where.not(id: owned_player_ids)
                             .includes(:positions)
                             .to_a
    end

    def qualified_player_ids
      Player.joins(:player_season_stats)
            .where(player_season_stats: { season: Season.second_to_last, played_matches: MIN_APPEARANCES.. })
            .where('player_season_stats.club_id = players.club_id')
            .select(:id)
    end

    def owned_player_ids
      league = auction_bid.team.league
      return [] unless league

      PlayerTeam.joins(:team).where(teams: { league_id: league.id }).select(:player_id)
    end

    def tournament
      @tournament ||= auction_bid.join&.tournament || auction_bid.team.tournament
    end
  end
end
