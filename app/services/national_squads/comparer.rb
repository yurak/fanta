module NationalSquads
  class Comparer < ApplicationService
    Result = Struct.new(:gone, :arrived, :ours_count, :theirs_count, keyword_init: true) do
      def changed?
        gone.any? || arrived.any?
      end
    end

    ALIASES = {
      'Spain' => {
        'Rodrigo Hernandez' => 'Rodri',  # Rodri, player #790
        'Pedri Gonzalez' => 'Pedri'      # Pedri, player #2341
      }
    }.freeze

    attr_reader :team, :ours, :theirs

    # ours: [String], theirs: [{ name:, position:, club:, birth_date: }]
    def initialize(team, ours, theirs)
      @team = team
      @ours = ours.uniq
      @theirs = theirs
    end

    def call
      mine = ours.map { |name| [name, tokens_for(name)] }
      yours = theirs.map { |player| [player, parts(player[:name])] }
      matched_mine, matched_yours = pair_up(mine, yours)

      Result.new(
        gone: mine.each_with_index.reject { |_, i| matched_mine.include?(i) }.map { |(name, _), _| name },
        arrived: yours.each_with_index.reject { |_, j| matched_yours.include?(j) }.map { |(player, _), _| player },
        ours_count: mine.size, theirs_count: yours.size
      )
    end

    private

    def pair_up(mine, yours)
      scored = mine.each_with_index.flat_map do |(_, my_tokens), i|
        yours.each_with_index.filter_map do |(_, your_tokens), j|
          shared = (my_tokens & your_tokens).size
          [shared, i, j] if shared.positive?
        end
      end

      taken_mine = Set.new
      taken_yours = Set.new
      scored.sort.reverse_each do |_, i, j|
        next if taken_mine.include?(i) || taken_yours.include?(j)

        taken_mine << i
        taken_yours << j
      end

      [taken_mine, taken_yours]
    end

    def tokens_for(name)
      alias_name = ALIASES.dig(team, name)

      parts(name) | (alias_name ? parts(alias_name) : Set.new)
    end

    # Name words, stripped to plain ASCII so spellings of the same name meet.
    def parts(name)
      folded = name.to_s.tr('ıİ', 'iI')
      folded = Players::Transfermarkt::NameNormalizer.normalize_name(folded)

      folded.downcase.gsub(/[^a-z ]/, ' ').split.to_set
    end
  end
end
