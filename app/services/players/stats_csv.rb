require 'csv'

module Players
  class StatsCsv < ApplicationService
    HEADERS = [
      'player', 'club', 'pos1', 'pos2', 'pos3', 'TM url', 'TM price', 'played matches', 'sixties',
      'average score', 'average total score', 'goals', 'assists', 'scored_penalty', 'failed penalty',
      'cleansheet', 'missed goals', 'missed penalty', 'caught penalty', 'saves', 'yellow_card', 'red_card',
      'own_goals', 'conceded_penalty', 'penalties_won', 'played_minutes', 'fotmob', 'min price', 'season clubs'
    ].freeze

    COUNT_COLUMNS = %i[
      goals assists scored_penalty failed_penalty cleansheet missed_goals missed_penalty
      caught_penalty saves yellow_card red_card own_goals conceded_penalty penalties_won played_minutes
    ].freeze

    def initialize(season:, player_ids: nil)
      @season = season
      @player_ids = player_ids
    end

    def call
      CSV.generate do |csv|
        csv << HEADERS
        rows.each { |row| csv << row }
      end
    end

    private

    def rows
      players.map { |player| row(player) }
             .sort_by { |row| [row[1].to_s, row[0].to_s] } # club, player name
    end

    def players
      scope = Player.includes(:positions, :club, player_season_stats: :club)
      scope = scope.where(id: @player_ids) if @player_ids
      scope
    end

    def row(player)
      season_stats = player.player_season_stats.select { |stat| stat.season_id == @season.id }

      descriptive(player) + stat_columns(season_stats) + tail(player, season_stats)
    end

    def stat_columns(season_stats)
      played = season_stats.sum(&:played_matches)

      [played, season_stats.sum(&:sixties),
       weighted(season_stats, :score, played), weighted(season_stats, :final_score, played)] +
        COUNT_COLUMNS.map { |column| season_stats.sum(&column) }
    end

    def tail(player, season_stats)
      representative = season_stats.max_by(&:played_matches)

      [player.fotmob_id, representative&.position_price, season_clubs(season_stats)]
    end

    def descriptive(player)
      positions = player.positions.first(3).map(&:human_name)

      [
        player.full_name_reverse, player.club&.name,
        positions[0], positions[1], positions[2], player.tm_url, player.tm_price
      ]
    end

    def season_clubs(season_stats)
      season_stats.filter_map { |stat| stat.club&.name }.uniq.sort.join(', ')
    end

    def weighted(player_stats, column, played)
      return decimal(0) if played.zero?

      decimal((player_stats.sum { |stat| stat.public_send(column) * stat.played_matches } / played).round(2))
    end

    def decimal(value)
      format('%.2f', value).tr('.', ',')
    end
  end
end
