module Scores
  module Injectors
    class SofascoreIncidents
      CARD_TYPE = 'card'.freeze
      GOAL_TYPE = 'goal'.freeze
      SUBSTITUTION_TYPE = 'substitution'.freeze
      PENALTY_CLASS = 'penalty'.freeze
      YELLOW_CLASS = 'yellow'.freeze
      RED_CLASSES = %w[red yellowRed].freeze

      def initialize(incidents_data)
        @incidents_data = incidents_data
      end

      # {sofascore_id => { yellow_card:, red_card: }}
      def cards
        @cards ||= incidents.select { |incident| card?(incident) }
                            .each_with_object({}) { |incident, hash| assign_card(hash, incident) }
      end

      # {sofascore_id => minute}, for the players sent off
      def red_card_minutes
        @red_card_minutes ||= incidents.select { |incident| card?(incident) && RED_CLASSES.include?(incident['incidentClass']) }
                                       .to_h { |incident| [player_id(incident), minute_of(incident)] }
      end

      # {sofascore_id => { on_minute:, off_minute: }}
      def substitutions
        @substitutions ||= incidents.select { |incident| incident['incidentType'] == SUBSTITUTION_TYPE }
                                    .each_with_object({}) { |incident, hash| assign_substitution(hash, incident) }
      end

      # {sofascore_id => count}
      def penalty_goals
        @penalty_goals ||= penalty_goal_incidents.each_with_object(Hash.new(0)) do |incident, hash|
          hash[player_id(incident)] += 1
        end
      end

      def goal_minutes_conceded_by(home:)
        goal_incidents.reject { |incident| incident['isHome'] == home }.map { |incident| minute_of(incident) }
      end

      def penalty_minutes_conceded_by(home:)
        penalty_goal_incidents.reject { |incident| incident['isHome'] == home }.map { |incident| minute_of(incident) }
      end

      private

      attr_reader :incidents_data

      def incidents
        @incidents ||= JSON.parse(incidents_data.to_s)['incidents'] || []
      rescue JSON::ParserError, TypeError
        @incidents = []
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

      def assign_substitution(hash, incident)
        minute = minute_of(incident)
        in_id = incident.dig('playerIn', 'id')
        out_id = incident.dig('playerOut', 'id')
        (hash[in_id] ||= {})[:on_minute] = minute if in_id
        (hash[out_id] ||= {})[:off_minute] = minute if out_id
      end

      def goal_incidents
        @goal_incidents ||= incidents.select { |incident| incident['incidentType'] == GOAL_TYPE }
      end

      def penalty_goal_incidents
        @penalty_goal_incidents ||= incidents.select do |incident|
          incident['incidentType'] == GOAL_TYPE && incident['incidentClass'] == PENALTY_CLASS && player_id(incident)
        end
      end

      def minute_of(incident)
        incident['time'].to_i + incident['addedTime'].to_i
      end

      def player_id(incident)
        incident.dig('player', 'id')
      end
    end
  end
end
