module Scores
  module Injectors
    class SofascoreMatch < BaseMatch
      DEFAULT_SCORE = 6.5
      FINISHED_STATUS = 'finished'.freeze
      CARD_TYPE = 'card'.freeze
      GOAL_TYPE = 'goal'.freeze
      SUBSTITUTION_TYPE = 'substitution'.freeze
      PENALTY_CLASS = 'penalty'.freeze
      YELLOW_CLASS = 'yellow'.freeze
      RED_CLASSES = %w[red yellowRed].freeze

      def call
        return if match.base_data.blank?
        return if match.lineups_data.blank?
        return unless match_finished?

        TournamentMatch.transaction do
          match.update(host_score: host_result, guest_score: guest_result, status: :finished)

          update_round_players

          audit_missed_players(host_scores_hash.merge(guest_scores_hash))
        end
      end

      private

      def update_round_players
        return if match.tournament_round.tournament.national?

        round_players.by_club(match.host_club_id).each { |rp| update_round_player(rp, host_scores_hash, conceded_for(home: true)) }
        round_players.by_club(match.guest_club.id).each { |rp| update_round_player(rp, guest_scores_hash, conceded_for(home: false)) }
      end

      def conceded_for(home:)
        {
          total: home ? guest_result : host_result,
          minutes: goal_minutes_conceded_by(home: home),
          penalty_minutes: penalty_minutes_conceded_by(home: home)
        }
      end

      def update_round_player(round_player, team_hash, conceded)
        player_data = team_hash[round_player.sofascore_id]

        if player_data
          round_player.update(round_player_params(round_player, player_data, conceded))
          team_hash.except!(round_player.sofascore_id)
        elsif squad_sofascore_ids.include?(round_player.sofascore_id)
          round_player.update(in_squad: true)
        end
      end

      def full_player_hash(round_player, data, conceded)
        sofascore_id = data[:sofascore_id]
        scored_penalty = penalty_goals[sofascore_id].to_i
        window = keeper_window(data)
        missed_penalty = missed_penalty_for(round_player, conceded, window)
        {
          score: rating(data), goals: goals_without_penalties(data, scored_penalty),
          assists: stat_value(data, :assists),
          cleansheet: cleansheet?(round_player, conceded[:total].to_i, data[:played_minutes],
                                  timing: cleansheet_timing(data, conceded)),
          own_goals: stat_value(data, :own_goals), saves: stat_value(data, :saves),
          missed_goals: missed_goals_for(round_player, conceded, window) - missed_penalty,
          missed_penalty: missed_penalty, scored_penalty: scored_penalty,
          caught_penalty: stat_value(data, :caught_penalty), failed_penalty: stat_value(data, :failed_penalty),
          conceded_penalty: stat_value(data, :conceded_penalty), penalties_won: stat_value(data, :penalties_won),
          played_minutes: stat_value(data, :played_minutes), in_squad: true,
          yellow_card: cards.dig(sofascore_id, :yellow_card) || false,
          red_card: cards.dig(sofascore_id, :red_card) || false
        }
      end

      def cleansheet_timing(data, conceded)
        return nil unless timed?(conceded)

        substitution = substitutions[data[:sofascore_id]] || {}
        { on_minute: substitution[:on_minute], off_minute: substitution[:off_minute],
          conceded_minutes: conceded[:minutes] }
      end

      def timed?(conceded)
        minutes = conceded[:minutes]
        minutes.present? && minutes.size == conceded[:total].to_i
      end

      def goals_without_penalties(data, scored_penalty)
        [stat_value(data, :goals).to_i - scored_penalty, 0].max
      end

      def missed_goals_for(round_player, conceded, window)
        return 0 unless round_player.position_names.include?(Position::GOALKEEPER)
        return conceded[:total].to_i unless timed?(conceded)

        goals_in_window(conceded[:minutes], window)
      end

      def missed_penalty_for(round_player, conceded, window)
        return 0 unless round_player.position_names.include?(Position::GOALKEEPER)
        return [conceded[:penalty_minutes].to_a.size, conceded[:total].to_i].min unless timed?(conceded)

        goals_in_window(conceded[:penalty_minutes], window)
      end

      def goals_in_window(minutes, window)
        minutes.to_a.count { |minute| minute > window[:on] && minute <= window[:off] }
      end

      def keeper_window(data)
        substitution = substitutions[data[:sofascore_id]] || {}
        { on: substitution[:on_minute].to_i, off: substitution[:off_minute] || Float::INFINITY }
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
        stats = player_data['statistics']
        {
          sofascore_id: player_data['player']['id'],
          source_name: player_data['player']['name'],
          rating: stats['rating'],
          played_minutes: stats['minutesPlayed'],
          goals: stats['goals'],
          assists: stats['goalAssist'],
          own_goals: stats['ownGoals'],
          saves: stats['saves'],
          caught_penalty: stats['penaltySave'],
          failed_penalty: stats['penaltyMiss'],
          conceded_penalty: stats['penaltyConceded'],
          penalties_won: stats['penaltyWon']
        }
      end

      def cards
        @cards ||= incidents.select { |incident| card?(incident) }
                            .each_with_object({}) { |incident, hash| assign_card(hash, incident) }
      end

      def card?(incident)
        incident['incidentType'] == CARD_TYPE && !incident['rescinded'] && player_id(incident)
      end

      def assign_card(hash, incident)
        entry = hash[player_id(incident)] ||= { yellow_card: false, red_card: false }
        incident_class = incident['incidentClass']

        if RED_CLASSES.include?(incident_class)
          entry.merge!(red_card: true, yellow_card: false)
        elsif incident_class == YELLOW_CLASS && !entry[:red_card]
          entry[:yellow_card] = true
        end
      end

      def penalty_goals
        @penalty_goals ||= penalty_goal_incidents.each_with_object(Hash.new(0)) do |incident, hash|
          hash[player_id(incident)] += 1
        end
      end

      def penalty_minutes_conceded_by(home:)
        penalty_goal_incidents.reject { |incident| incident['isHome'] == home }.map { |i| minute_of(i) }
      end

      def goal_minutes_conceded_by(home:)
        goal_incidents.reject { |incident| incident['isHome'] == home }.map { |incident| minute_of(incident) }
      end

      def goal_incidents
        @goal_incidents ||= incidents.select { |incident| incident['incidentType'] == GOAL_TYPE }
      end

      def substitutions
        @substitutions ||= incidents.select { |incident| incident['incidentType'] == SUBSTITUTION_TYPE }
                                    .each_with_object({}) { |incident, hash| assign_substitution(hash, incident) }
      end

      def assign_substitution(hash, incident)
        minute = minute_of(incident)
        in_id = incident.dig('playerIn', 'id')
        out_id = incident.dig('playerOut', 'id')
        (hash[in_id] ||= {})[:on_minute] = minute if in_id
        (hash[out_id] ||= {})[:off_minute] = minute if out_id
      end

      def minute_of(incident)
        incident['time'].to_i + incident['addedTime'].to_i
      end

      def penalty_goal_incidents
        @penalty_goal_incidents ||= incidents.select do |incident|
          incident['incidentType'] == GOAL_TYPE && incident['incidentClass'] == PENALTY_CLASS && player_id(incident)
        end
      end

      def player_id(incident)
        incident.dig('player', 'id')
      end

      def incidents
        @incidents ||= JSON.parse(match.incidents_data.to_s)['incidents'] || []
      rescue JSON::ParserError, TypeError
        @incidents = []
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
