module Manage
  class ChampionsMatrix
    MAX_SHADE = 7

    def initialize(champions)
      @champions = champions.to_a
    end

    attr_reader :champions

    def tournaments
      @tournaments ||= Tournament.where(id: by_tournament.keys.map(&:last).compact.uniq).order(:id).to_a
    end

    def seasons
      @seasons ||= by_season.keys.filter_map(&:last).uniq.sort_by { |season| [season[0, 4].to_i, season.length] }
    end

    def titles_in(user, tournament)
      by_tournament[[user.id, tournament.id]].to_i
    end

    def titles_in_season(user, season)
      by_season[[user.id, season]].to_i
    end

    def total(user)
      totals[user.id].to_i
    end

    def shade(count)
      return nil if count.zero?

      [count, MAX_SHADE].min
    end

    # an empty cell carries no shade class at all, so the hover rule can tint it like the plain
    # columns without having to outrank a fill
    def cell_classes(count)
      ['champions-matrix-cell', ("champions-matrix-shade-#{shade(count)}" if count.positive?)]
    end

    def season_label(season)
      years = season.to_s.split('/').map { |year| year[-2, 2] }

      years.join('/')
    end

    private

    def user_ids
      @user_ids ||= champions.map(&:id)
    end

    def by_tournament
      @by_tournament ||= UserTitle.where(user_id: user_ids).group(:user_id, :tournament_id).count
    end

    def by_season
      @by_season ||= UserTitle.where(user_id: user_ids).group(:user_id, :season).count
    end

    def totals
      @totals ||= UserTitle.where(user_id: user_ids).group(:user_id).count
    end
  end
end
