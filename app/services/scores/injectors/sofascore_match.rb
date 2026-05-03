module Scores
  module Injectors
    class SofascoreMatch < BaseMatch
      DEFAULT_SCORE = 6.5
      FINISHED_STATUS = 'finished'.freeze

      def call
        return if match.base_data.blank?
        return if match.lineups_data.blank?
        return unless match_finished?

        TournamentMatch.transaction do
          match.update(host_score: host_result, guest_score: guest_result)

          update_round_players

          audit_missed_players(host_scores_hash.merge(guest_scores_hash))
        end
      end

      private

      def update_round_players
        return if match.tournament_round.tournament.national?

        round_players.by_club(match.host_club_id).each { |rp| update_round_player(rp, host_scores_hash, guest_result) }
        round_players.by_club(match.guest_club.id).each { |rp| update_round_player(rp, guest_scores_hash, host_result) }
      end

      def update_round_player(round_player, team_hash, team_missed_goals)
        player_data = team_hash[round_player.sofascore_id]

        if player_data
          round_player.update(round_player_params(round_player, player_data, team_missed_goals))
          team_hash.except!(round_player.sofascore_id)
        elsif squad_sofascore_ids.include?(round_player.sofascore_id)
          round_player.update(in_squad: true)
        end
      end

      def full_player_hash(round_player, data, team_missed_goals)
        # Unsupported params: yellow_card red_card failed_penalty caught_penalty conceded_penalty penalties_won scored_penalty
        {
          score: rating(data), goals: stat_value(data, :goals), assists: stat_value(data, :assists),
          cleansheet: cleansheet?(round_player, team_missed_goals.to_i, data[:played_minutes]),
          own_goals: stat_value(data, :own_goals), saves: stat_value(data, :saves),
          missed_goals: missed_goals(round_player, team_missed_goals.to_i),
          played_minutes: stat_value(data, :played_minutes), in_squad: true
        }
      end

      def rating(player_data)
        return DEFAULT_SCORE if (player_data[:rating].nil? || player_data[:rating].zero?) && player_data[:played_minutes]&.positive?

        player_data[:rating].to_f.round(1)
      end

      def build_players_hash(players)
        players.each_with_object({}) do |player_data, hash|
          stats = player_data['statistics']
          next unless stats
          next if stats['minutesPlayed'].to_i.zero?

          hash[player_data['player']['id']] = build_player_hash(player_data)
        end
      end

      def build_player_hash(player_data)
        # TODO: add stats
        # caught_penalty: player_stats(player_data, 'Saved penalties'),
        # failed_penalty: player_stats(player_data, 'Missed penalty'),
        # conceded_penalty: player_stats(player_data, 'Conceded penalty'),
        # penalties_won: player_stats(player_data, 'Penalties won')
        # yellow_card: card?(player_data['events']['yc']),
        # red_card: card?(player_data['events']['ycrc']) || card?(player_data['events']['rc'])
        stats = player_data['statistics']
        {
          sofascore_id: player_data['player']['id'],
          source_name: player_data['player']['name'],
          rating: stats['rating'],
          played_minutes: stats['minutesPlayed'],
          goals: stats['goals'],
          assists: stats['goalAssist'],
          own_goals: stats['ownGoals'],
          saves: stats['saves']
        }
      end

      def squad_sofascore_ids
        @squad_sofascore_ids ||= (team_player_ids('home') + team_player_ids('away')).to_set
      end

      def team_player_ids(team)
        lineups_data[team]&.dig('players')&.map { |p| p['player']['id'] } || []
      end

      def host_scores_hash
        @host_scores_hash ||= lineups_data['home'] ? build_players_hash(lineups_data['home']['players']) : {}
      end

      def guest_scores_hash
        @guest_scores_hash ||= lineups_data['away'] ? build_players_hash(lineups_data['away']['players']) : {}
      end

      def lineups_data
        @lineups_data ||= JSON.parse(match.lineups_data)
      rescue JSON::ParserError
        @lineups_data = {}
      end

      def host_result
        @host_result ||= event_data['homeScore']['display']
      end

      def guest_result
        @guest_result ||= event_data['awayScore']['display']
      end

      def match_finished?
        event_status == FINISHED_STATUS && player_stats?
      end

      def player_stats?
        event_data['hasEventPlayerStatistics']
      end

      def event_status
        @event_status ||= event_data.dig('status', 'type')
      end

      def event_data
        @event_data ||= JSON.parse(match.base_data)['event']
      rescue JSON::ParserError
        @event_data = {}
      end
    end
  end
end
