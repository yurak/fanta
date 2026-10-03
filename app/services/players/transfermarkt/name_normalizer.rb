module Players
  module Transfermarkt
    module NameNormalizer
      module_function

      def normalize_name(str)
        I18n.transliterate(str.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, ''))
      end
    end
  end
end
