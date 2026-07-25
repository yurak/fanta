require 'csv'

module Players
  class StatsCsv < ApplicationService
    HEADERS = [
      'player', 'club', 'pos1', 'pos2', 'pos3', 'TM url', 'TM price', 'played matches', 'sixties',
      'average score', 'average total score', 'goals', 'assists', 'scored_penalty', 'failed penalty',
      'cleansheet', 'missed goals', 'missed penalty', 'caught penalty', 'saves', 'yellow_card', 'red_card',
      'own_goals', 'conceded_penalty', 'penalties_won', 'played_minutes', 'fotmob', 'min price'
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
      stats.group_by(&:player_id)
           .values
           .map { |player_stats| row(player_stats) }
           .sort_by { |row| [row[1].to_s, row[0].to_s] } # club, player name
    end

    def stats
      scope = PlayerSeasonStat.where(season_id: @season.id).includes(player: %i[positions club])
      scope = scope.where(player_id: @player_ids) if @player_ids
      scope
    end

    def row(player_stats)
      representative = player_stats.max_by(&:played_matches)
      played = player_stats.sum(&:played_matches)

      descriptive(representative) +
        [played, player_stats.sum(&:sixties),
         weighted(player_stats, :score, played), weighted(player_stats, :final_score, played)] +
        COUNT_COLUMNS.map { |column| player_stats.sum(&column) } +
        [representative.player.fotmob_id, representative.position_price]
    end

    def descriptive(stat)
      player = stat.player
      positions = player.positions.first(3).map(&:human_name)

      [
        player.full_name_reverse, player.club&.name,
        positions[0], positions[1], positions[2], player.tm_url, player.tm_price
      ]
    end

    def weighted(player_stats, column, played)
      return 0 if played.zero?

      (player_stats.sum { |stat| stat.public_send(column) * stat.played_matches } / played).round(2)
    end
  end
end
