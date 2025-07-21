module Stats
  class PriceUpdater < ApplicationService
    attr_reader :tournament

    PRICE_5 = 5
    PRICE_10 = 10
    PRICE_15 = 15
    PRICE_20 = 20
    SCORE_8_0 = 8.0
    SCORE_8_5 = 8.5
    SCORE_9_0 = 9.0

    def initialize(tournament)
      @tournament = tournament
    end

    def call
      return false unless tournament

      ids = stats.where('final_score >= ?', 8.0).map(&:id)

      Position::LIST.each do |position|
        ids << stats.joins(player: :positions).where(player: { positions: { name: position } })
                    .order(final_score: :desc).limit(5).map(&:id)
      end

      price_stats = stats.where(id: ids.flatten.uniq!)
      price_stats.each do |stat|
        stat.update(position_price: price(stat.final_score))
      end

      true
    end

    private

    def price(final_score)
      if final_score >= SCORE_9_0
        PRICE_20
      elsif final_score >= SCORE_8_5
        PRICE_15
      elsif final_score >= SCORE_8_0
        PRICE_10
      else
        PRICE_5
      end
    end

    def stats
      @stats ||= tournament.player_season_stats.by_season(season).played_minimum
    end

    def season
      @season ||= Season.last
    end
  end
end
