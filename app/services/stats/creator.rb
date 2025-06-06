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
        next if matches_w_scores(player).empty?

        matches_w_scores(player).group_by(&:club_id).each do |club_data|
          club = Club.find_by(id: club_data[0])
          next unless club

          matches = RoundPlayer.where(id: club_data[1].pluck(:id))
          stats(player, club).update(stats_hash(player, matches))
        end
      end

      true
    end

    private

    def stats(player, club)
      PlayerSeasonStat.find_or_create_by(player: player, season: season, club: club, tournament: club.tournament)
    end

    def matches_w_scores(player)
      player.round_players.with_score.by_tournament_round(rounds)
    end

    def rounds
      @rounds ||= TournamentRound.by_tournament(Tournament.with_clubs).by_season(season)
    end

    def stats_hash(player, matches)
      {
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
        sixties: player.sixty_minutes_plus(matches),
        position1: player.positions[0]&.name,
        position2: player.positions[1]&.name,
        position3: player.positions[2]&.name
      }
    end
  end
end
# rubocop:enable Metrics/MethodLength
