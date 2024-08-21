module Scores
  module Injectors
    class SofascoreMatch < BaseMatch
      # EVENT_URL = 'https://www.sofascore.com/api/v1/event/'.freeze
      STATS = '/stats/'.freeze
      LINEUPS = '/lineups'.freeze

      private

      def update_round_players
        return if match.tournament_round.tournament.national?

        round_players.by_club(match.host_club_id).each { |rp| update_round_player(rp, host_scores_hash, guest_result) }
        round_players.by_club(match.guest_club.id).each { |rp| update_round_player(rp, guest_scores_hash, host_result) }
      end

      def update_round_player(round_player, team_hash, team_missed_goals)
        player_data = team_hash[round_player.sofascore_id]
        return unless player_data

        round_player.update(round_player_params(round_player, player_data, team_missed_goals))

        team_hash.except!(round_player.sofascore_id)
      end

      def full_player_hash(round_player, data, team_missed_goals)
        # Unsupported params: yellow_card red_card failed_penalty caught_penalty conceded_penalty penalties_won scored_penalty
        {
          score: rating(data), goals: stat_value(data, :goals), assists: stat_value(data, :assists),
          cleansheet: cleansheet?(round_player, team_missed_goals.to_i, data[:played_minutes]),
          own_goals: stat_value(data, :own_goals), saves: stat_value(data, :saves),
          missed_goals: missed_goals(round_player, team_missed_goals.to_i),
          played_minutes: stat_value(data, :played_minutes)
        }
      end

      def players_hash(players)
        players.each_with_object({}) do |player_data, hash|
          next unless player_data['statistics']
          next if player_data['statistics']['minutesPlayed'].to_i.zero?

          hash[player_data['player']['id']] = player_hash(player_data)
        end
      end

      def player_hash(player_data)
        # TODO: add stats
        # missed_goals: player_stats(player_data, 'Goals conceded'),
        # caught_penalty: player_stats(player_data, 'Saved penalties'),
        # failed_penalty: player_stats(player_data, 'Missed penalty'),
        # conceded_penalty: player_stats(player_data, 'Conceded penalty'),
        # penalties_won: player_stats(player_data, 'Penalties won')
        # yellow_card: card?(player_data['events']['yc']),
        # red_card: card?(player_data['events']['ycrc']) || card?(player_data['events']['rc'])
        {
          sofascore_id: player_data['player']['id'],
          source_name: player_data['player']['name'],
          rating: player_data['statistics']['rating'],
          played_minutes: player_data['statistics']['minutesPlayed'],
          goals: player_data['statistics']['goals'],
          assists: player_data['statistics']['goalAssist'],
          own_goals: player_data['statistics']['ownGoals'],
          saves: player_data['statistics']['saves']
        }
      end

      def host_scores_hash
        return {} unless lineups_data['home']

        @host_scores_hash ||= players_hash(lineups_data['home']['players'])
      end

      def guest_scores_hash
        return {} unless lineups_data['away']

        @guest_scores_hash ||= players_hash(lineups_data['away']['players'])
      end

      def lineups_data
        @lineups_data ||= JSON.parse(lineups_request)['data']
      rescue
        @lineups_data = {}
      end

      def lineups_request
        RestClient.get(event_url + LINEUPS)
      end

      def host_result
        @host_result ||= event_data['homeScore']['display']
      end

      def guest_result
        @guest_result ||= event_data['awayScore']['display']
      end

      def match_finished?
        event_status == 'finished' && player_stats?
      end

      def player_stats?
        event_data['hasEventPlayerStatistics']
      end

      def event_status
        return unless event_data['status']

        @event_status ||= event_data['status']['type']
      end

      def event_data
        @event_data ||= JSON.parse(event_request)['data']['event']
      rescue
        @event_data = {}
      end

      def event_request
        RestClient.get(event_url)
      end

      def event_url
        @event_url ||= "#{resource_url}#{STATS}#{match.source_match_id}"
      end

      def resource_url
        Configuration.sofa_server_url
      end
    end
  end
end
