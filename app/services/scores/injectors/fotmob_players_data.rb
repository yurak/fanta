module Scores
  module Injectors
    class FotmobPlayersData < ApplicationService
      CARD_TYPE = 'Card'.freeze
      GOAL_TYPE = 'Goal'.freeze
      PENALTY_KEY = 'penalty'.freeze
      RED_CARD = 'Red'.freeze
      YELLOW_CARD = 'Yellow'.freeze
      YEL_RED_CARD = 'YellowRed'.freeze

      attr_reader :events_data, :players_data

      def initialize(match_data)
        @players_data = match_data['playerStats']
        @events_data = match_data['matchFacts']['events']['events']
      end

      def call
        return {} unless players_data

        hash = process_players_stats(players_data)
        process_events(hash)
        hash
      end

      private

      def process_players_stats(players_data)
        players_data.each_with_object({}) do |player_data, hash|
          hash[player_data.first.to_i] = player_hash(player_data)
        end
      end

      def player_hash(player_data)
        hash = {
          fotmob_id: player_data.first.to_i,
          fotmob_name: player_name(player_data)
        }
        return hash if player_data.second['stats'].empty?

        hash.merge(top_stats_hash(player_data)).compact
      end

      def top_stats_hash(player_data)
        top_stats = player_data.second['stats'].find { |h| h['key'] == 'top_stats' }['stats']

        {
          rating: player_stats(top_stats, 'FotMob rating').round(1),
          played_minutes: player_stats(top_stats, 'Minutes played'),
          goals: player_stats(top_stats, 'Goals'),
          assists: player_stats(top_stats, 'Assists'),
          missed_goals: player_stats(top_stats, 'Goals conceded'),
          penalty_missed_goals: player_stats(top_stats, 'Penalty goals conceded'),
          own_goals: player_stats(top_stats, 'Own goal'),
          conceded_penalty: player_stats(top_stats, 'Conceded penalty'),
          penalties_won: player_stats(top_stats, 'Penalties won'),
          caught_penalty: player_stats(top_stats, 'Saved penalties'),
          failed_penalty: player_stats(top_stats, 'Missed penalty'),
          saves: player_stats(top_stats, 'Saves')
        }
      end

      def player_stats(player_data, key)
        player_data[key] ? player_data[key]['stat']['value'] : 0
      end

      def process_events(hash)
        cards_events = events_data.select { |event| event['type'] == CARD_TYPE }
        process_cards(hash, cards_events)

        penalty_events = events_data.select { |event| event['type'] == GOAL_TYPE && event['goalDescriptionKey'] == PENALTY_KEY }
        process_penalties(hash, penalty_events)
      end

      def process_cards(hash, events)
        events.each do |event_data|
          player_id = event_data['player']['id']
          next unless hash[player_id]

          hash[player_id][:yellow_card] = 1 if event_data['card'] == YELLOW_CARD
          hash[player_id][:red_card] = 1 if event_data['card'] == RED_CARD
          if event_data['card'] == YEL_RED_CARD
            hash[player_id][:red_card] = 1
            hash[player_id][:yellow_card] = 0
          end
        end
      end

      def process_penalties(hash, events)
        events.each do |event_data|
          player_id = event_data['player']['id']
          next unless hash[player_id]

          hash[player_id][:goals] -= 1
          hash[player_id][:scored_penalty] = hash[player_id][:scored_penalty].to_i + 1
        end
      end

      def player_name(player_data)
        player_data.second['name'].lstrip.unicode_normalize(:nfd).gsub(/[^\x00-\x7F]/n, '').downcase
      end
    end
  end
end
