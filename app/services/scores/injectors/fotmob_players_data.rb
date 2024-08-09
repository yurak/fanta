module Scores
  module Injectors
    class FotmobPlayersData < ApplicationService
      attr_reader :team_data

      def initialize(team_data)
        @team_data = team_data
      end

      def call
        players_hash(team_data)
      end

      private

      def players_hash(team)
        scores_hash = team['starters'].each_with_object({}) do |player_data, hash|
          hash[player_data['id']] = starter_hash(player_data)
        end

        team['subs'].each_with_object(scores_hash) do |player_data, hash|
          player_hash = subs_hash(player_data)
          hash[player_data['id']] = player_hash unless player_hash[:played_minutes].zero?
        end
      end

      def starter_hash(player_data)
        hash = {
          fotmob_id: player_data['id'],
          fotmob_name: player_name(player_data),
          rating: player_data['performance']['rating'],
          played_minutes: played_minutes(player_data['performance']['substitutionEvents'], starter: true)
        }
        hash = hash.merge(events_data(player_data['performance']['events'])) if player_data['performance']['events'].any?
        hash
      end

      def subs_hash(player_data)
        starter_hash(player_data).merge(played_minutes: played_minutes(player_data['performance']['substitutionEvents']))
      end

      def player_name(player_data)
        player_data['name'].lstrip.unicode_normalize(:nfd).gsub(/[^\x00-\x7F]/n, '').downcase.to_s
      end

      def played_minutes(player_subs_data, starter: false)
        start_min = 0
        end_min = starter ? 90 : 0

        player_subs_data.each do |sub|
          end_min = sub['time'] if sub['type'] == 'subOut'
          if sub['type'] == 'subIn'
            end_min = 90
            start_min = sub['time'] - 1
          end
        end
        end_min - start_min
      end

      def events_data(player_data)
        player_data.each_with_object({}) do |event, hash|
          type = event['type'].underscore
          if type == 'second_yellow'
            hash['yellow_card'] = 0
            hash['red_card'] = 1
            next
          end

          hash[type] ? hash[type] += 1 : hash[type] = 1
        end
      end
    end
  end
end
