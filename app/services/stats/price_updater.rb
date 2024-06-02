module Stats
  class PriceUpdater < ApplicationService
    attr_reader :tournament

    def initialize(tournament)
      @tournament = tournament
    end

    def call
      return false unless tournament

      ids = stats.where('final_score >= ?', 8.0).map(&:id)

      Position::LIST.each do |position|
        # TODO: update price by new player position
        ids << stats.by_position(position).order(final_score: :desc).limit(5).map(&:id)
      end

      price_stats = stats.where(id: ids.flatten.uniq!)
      price_stats.each do |stat|
        stat.update(position_price: price(stat.final_score))
      end

      true
    end

    private

    def price(final_score)
      if final_score >= 9.0
        20
      elsif final_score >= 8.5
        15
      elsif final_score >= 8.0
        10
      else
        5
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
