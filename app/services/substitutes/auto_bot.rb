module Substitutes
  class AutoBot
    attr_reader :match_lineup, :preview

    def initialize(match_lineup, preview: false)
      @lineup_substitutes = []
      @substitutions = { out: [], in: [] }
      @match_lineup = match_lineup
      @preview = preview
    end

    def self.for_round(round, preview: true)
      round.tours.each do |tour|
        tour.autobot(preview: preview)
      end
    end

    def process
      substitute_malus_zero
      substitute if malus_substitute?

      if preview
        match_lineup.substitutes = @lineup_substitutes.to_json
        match_lineup.save
      end
      @lineup_substitutes
    end

    def substitute_malus_zero
      team_with_zero_maluses.each do |key, value|
        queue = value.sort.to_h
        queue.each do |_malus, benched_ids|
          in_id = benched_ids.detect { |benched_id| @substitutions[:in].exclude?(benched_id) }

          next unless in_id && key && @substitutions[:out].exclude?(key)

          Substitutes::Creator.call(key, in_id, 'autobot') unless preview
          @substitutions[:in] << in_id
          @substitutions[:out] << key
          @lineup_substitutes << { out: ui_string(key), in: ui_string(in_id) }
        end
      end
    end

    def substitute
      team.each do |key, value|
        queue = value.sort.to_h
        queue.each do |_malus, benched_ids|
          in_id = benched_ids.detect { |benched_id| @substitutions[:in].exclude?(benched_id) }

          next unless in_id && key && @substitutions[:out].exclude?(key)

          Substitutes::Creator.call(key, in_id, 'autobot') unless preview
          @substitutions[:in] << in_id
          @substitutions[:out] << key
          @lineup_substitutes << { out: ui_string(key), in: ui_string(in_id) }
        end
      end
    end

    def team
      team = {}
      main_lineup_players.each do |mp|
        mp.subs_options.each_with_object({}) do |so, memo|
          malus = Scores::PositionMalus::Counter.call(mp.real_position, so.position_names)
          if memo[malus]
            memo[malus] << so.id
          else
            memo[malus] = [so.id]
          end
          team[mp.id] = memo
        end
      end

      team
    end

    def team_with_zero_maluses
      team = {}
      main_lineup_players.each do |mp|
        mp.subs_options.each_with_object({}) do |so, memo|
          malus = Scores::PositionMalus::Counter.call(mp.real_position, so.position_names)
          next unless malus.zero?

          if memo[malus]
            memo[malus] << so.id
          else
            memo[malus] = [so.id]
          end
          team[mp.id] = memo
        end
      end

      team
    end

    private

    def malus_substitute?
      team.keys.size == 1 || one_malus_preview?
    end

    def one_malus_preview?
      preview && one_non_zero_team?
    end

    def one_non_zero_team?
      non_zero_hashes = team.values.count do |hash|
        hash.all? { |key, _| key != 0 }
      end

      non_zero_hashes == 1
    end

    def ui_string(id)
      MatchPlayer.find(id).player.full_name_with_positions
    end

    def main_lineup_players
      match_lineup.match_players.main.select(&:not_played?)
    end
  end
end
