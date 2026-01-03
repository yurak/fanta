# rubocop:disable Metrics/MethodLength:
module Stats
  class Creator < ApplicationService
    attr_reader :player_ids, :season

    def initialize(season_id: Season.last.id, player_ids: (1..Player.last.id).to_a)
      @season = Season.find_by(id: season_id)
      @player_ids = player_ids
    end

    def call
      player_ids.each do |id|
        player = Player.find_by(id: id)
        next unless player

        player_matches = matches_w_scores(player)
        next if player_matches.empty?

        player_matches.group_by(&:club_id).each do |club_id, matches_for_club|
          club = Club.find_by(id: club_id)
          next unless club

          matches = RoundPlayer.where(id: matches_for_club.pluck(:id))
          stats_record = stats(player, club)

          attrs = stats_hash(player, matches, include_positions: stats_record.new_record?)
          attrs[:tournament] = club.tournament if stats_record.new_record?

          stats_record.update!(attrs)
        end
      end

      true
    end

    private

    def stats(player, club)
      PlayerSeasonStat.find_or_initialize_by(player: player, season: season, club: club)
    end

    def matches_w_scores(player)
      player.round_players.with_score.by_tournament_round(rounds)
    end

    def rounds
      @rounds ||= TournamentRound.by_tournament(Tournament.with_clubs).by_season(season)
    end

    def stats_hash(player, matches, include_positions: true)
      hash = {
        played_matches: player.season_scores_count(matches),
        score: player.season_average_score(matches),
        final_score: player.season_average_result_score(matches),
        goals: player.season_bonus_count(matches, 'goals'),
        assists: player.season_bonus_count(matches, 'assists'),
        scored_penalty: player.season_bonus_count(matches, 'scored_penalty'),
        failed_penalty: player.season_bonus_count(matches, 'failed_penalty'),
        cleansheet: player.season_cards_count(matches, 'cleansheet'),
        missed_goals: player.season_bonus_count(matches, 'missed_goals'),
        missed_penalty: player.season_bonus_count(matches, 'missed_penalty'),
        caught_penalty: player.season_bonus_count(matches, 'caught_penalty'),
        saves: player.season_bonus_count(matches, 'saves'),
        yellow_card: player.season_cards_count(matches, 'yellow_card'),
        red_card: player.season_cards_count(matches, 'red_card'),
        own_goals: player.season_bonus_count(matches, 'own_goals'),
        conceded_penalty: player.season_bonus_count(matches, 'conceded_penalty'),
        penalties_won: player.season_bonus_count(matches, 'penalties_won'),
        played_minutes: player.season_bonus_count(matches, 'played_minutes'),
        sixties: player.sixty_minutes_plus(matches)
      }

      if include_positions
        hash.merge!(
          position1: player.positions[0]&.name,
          position2: player.positions[1]&.name,
          position3: player.positions[2]&.name
        )
      end

      hash
    end
  end
end
# rubocop:enable Metrics/MethodLength
