module Divisions
  class ExchangeCalculator < ApplicationService
    SAME_WIDTH_PROMOTION = 3
    NARROWER_PROMOTION = 2
    UNBALANCED_RELEGATION = 3

    Row = Struct.new(:level, :leagues, :promotion, :relegation, :balanced, keyword_init: true)

    def initialize(tournament, season, apply: false)
      @tournament = tournament
      @season = season
      @apply = apply
    end

    def call
      return [] if levels.size < 2

      rows = build_rows
      persist(rows) if apply

      rows
    end

    private

    attr_reader :tournament, :season, :apply

    def build_rows
      rows = levels.map do |level|
        Row.new(level: level, leagues: leagues_by_level[level].size,
                promotion: 0, relegation: 0, balanced: true)
      end

      rows.each_cons(2) do |upper, lower|
        lower.promotion = promotion_for(upper.leagues, lower.leagues)
        going_down = lower.promotion * lower.leagues

        if (going_down % upper.leagues).zero?
          upper.relegation = going_down / upper.leagues
        else
          upper.relegation = UNBALANCED_RELEGATION
          upper.balanced = false
        end
      end

      rows
    end

    def promotion_for(upper_count, lower_count)
      return SAME_WIDTH_PROMOTION if upper_count == lower_count
      return NARROWER_PROMOTION if ((NARROWER_PROMOTION * lower_count) % upper_count).zero?

      SAME_WIDTH_PROMOTION
    end

    def persist(rows)
      rows.each do |row|
        League.where(id: leagues_by_level[row.level].map(&:id))
              .update_all(promotion: row.promotion, relegation: row.relegation) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def levels
      @levels ||= leagues_by_level.keys.sort
    end

    def leagues_by_level
      @leagues_by_level ||= League.joins(:division)
                                  .where(tournament_id: tournament.id, season_id: season.id)
                                  .where.not(division_id: nil)
                                  .select('leagues.id, divisions.level AS division_level')
                                  .group_by(&:division_level)
    end
  end
end
