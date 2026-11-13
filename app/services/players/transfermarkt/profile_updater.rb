module Players
  module Transfermarkt
    class ProfileUpdater < ApplicationService
      FIELDS = %i[tm_price number birth_date height nationality].freeze

      attr_reader :player, :only

      def initialize(player, only: FIELDS)
        @player = player
        @only = Array(only) & FIELDS
      end

      def call
        return {} unless player&.tm_id

        data = parsed
        return {} unless data.is_a?(Hash)

        changes = changes_for(data)
        player.update(changes.transform_values(&:last)) if changes.any?
        changes
      end

      private

      def parsed
        Players::Transfermarkt::ApiParser.call(player.tm_id, position_skip: true)
      end

      def changes_for(data)
        only.each_with_object({}) do |field, acc|
          value = normalize(field, data[field])
          next if value.blank?

          was = player.public_send(field)
          next if comparable(was) == comparable(value)

          acc[field] = [was, value]
        end
      end

      def normalize(field, value)
        case field
        when :tm_price, :number, :height then value.to_i.positive? ? value.to_i : nil
        else value.presence
        end
      end

      def comparable(value)
        value.is_a?(BigDecimal) ? value.to_i : value
      end
    end
  end
end
