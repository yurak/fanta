# rubocop:disable Metrics/MethodLength:
module Stats
  class Creator < ApplicationService
    attr_reader :tournament

    def initialize(tournament)
      @tournament = tournament
    end

    def call
      return false unless tournament

      tournament.clubs.active.sort_by(&:name).each do |club|
        club.players.each do |player|
          next if player.season_scores_count.zero?

          # TODO: create statistics for each club where the player played during the season
          stats(player).update(stats_hash(player))
        end
      end

      true
    end

    private

    def matches(player)
      @matches ||= Hash.new do |h, key|
        h[key] = key.season_matches_with_scores
      end
      @matches[player]
    end

    def stats(player)
      PlayerSeasonStat.find_or_create_by(player: player, season: season, club: player.club, tournament: tournament)
    end

    def stats_hash(player)
      {
        played_matches: player.season_scores_count,
        score: player.season_average_score,
        final_score: player.season_average_result_score,
        goals: player.season_bonus_count(matches(player), 'goals'),
        assists: player.season_bonus_count(matches(player), 'assists'),
        scored_penalty: player.season_bonus_count(matches(player), 'scored_penalty'),
        failed_penalty: player.season_bonus_count(matches(player), 'failed_penalty'),
        cleansheet: player.season_cards_count(matches(player), 'cleansheet'),
        missed_goals: player.season_bonus_count(matches(player), 'missed_goals'),
        missed_penalty: player.season_bonus_count(matches(player), 'missed_penalty'),
        caught_penalty: player.season_bonus_count(matches(player), 'caught_penalty'),
        saves: player.season_bonus_count(matches(player), 'saves'),
        yellow_card: player.season_cards_count(matches(player), 'yellow_card'),
        red_card: player.season_cards_count(matches(player), 'red_card'),
        own_goals: player.season_bonus_count(matches(player), 'own_goals'),
        conceded_penalty: player.season_bonus_count(matches(player), 'conceded_penalty'),
        penalties_won: player.season_bonus_count(matches(player), 'penalties_won'),
        played_minutes: player.season_bonus_count(matches(player), 'played_minutes'),
        position1: player.positions[0]&.name,
        position2: player.positions[1]&.name,
        position3: player.positions[2]&.name
      }
    end

    def season
      @season ||= Season.last
    end
  end
end
# rubocop:enable Metrics/MethodLength
