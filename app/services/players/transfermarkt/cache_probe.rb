module Players
  module Transfermarkt
    module CacheProbe
      TTL = 7 * 86_400
      PATTERNS = ['player_api_%s.json', 'player_html_%s.html'].freeze

      module_function

      def fresh?(tm_id)
        return false if tm_id.blank?
        return false if ENV['TM_SKIP_CACHE'].present?

        PATTERNS.any? { |pattern| fresh_file?(format(pattern, tm_id)) }
      end

      def fresh_file?(name)
        path = Rails.root.join('tmp', 'transfermarkt_cache', name)

        path.exist? && (Time.zone.now.to_i - path.mtime.to_i) <= TTL
      end
    end
  end
end
