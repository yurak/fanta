module WeeklyTeams
  class AuctionAvgBuilder < ApplicationService
    include Assignable

    def initialize(tournament_id, season_id)
      @tournament_id = tournament_id
      @season_id     = season_id
    end

    def call
      prices = aggregate_prices
      return [] if prices.empty?

      TeamModule.includes(:slots).order(:name).map do |mod|
        [mod, assign(mod, prices)]
      end
    end

    private

    def aggregate_prices
      leagues_count = league_ids.size
      return {} if leagues_count.zero?

      min_leagues = (leagues_count / 2.0).ceil

      purchases.group_by(&:player_id).each_with_object({}) do |(_, transfers), hash|
        next if transfers.size < min_leagues

        build_entry(hash, transfers)
      end
    end

    def build_entry(hash, transfers)
      prices  = transfers.map(&:price)
      best    = transfers.max_by(&:price)

      hash[best.player_id] = {
        player: best.player,
        round_player: nil,
        total: (prices.sum / prices.size.to_f).round(2),
        max_price: prices.max,
        appearances: transfers.size
      }
    end

    def purchases
      Transfer.incoming
              .where(auction_id: primary_auction_ids)
              .includes(player: [:positions, { club: :tournament }])
              .to_a
    end

    def primary_auction_ids
      Auction.where(league_id: league_ids, number: 1).pluck(:id)
    end

    # only leagues assigned to a division are counted — they hold the competitive auctions
    def league_ids
      @league_ids ||= League.where(tournament_id: @tournament_id, season_id: @season_id)
                            .where.not(division_id: nil)
                            .pluck(:id)
    end

    def rank(prices)
      prices.values.sort_by { |h| -h[:total] }
    end
  end
end
