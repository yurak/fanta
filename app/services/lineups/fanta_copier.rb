module Lineups
  class FantaCopier < ApplicationService
    attr_reader :lineup

    def initialize(lineup)
      @lineup = lineup
    end

    def call
      return false unless lineup.tour.fanta?

      lineup.fanta_copy_targets.each do |target|
        copy_lineup_to(target[:tour], target[:team])
      end
    end

    private

    def copy_lineup_to(tour, team)
      new_lineup = lineup.dup
      new_lineup.update(tour: tour, team: team, final_score: 0,
                        final_goals: nil, substitutes: nil, creation_type: :copied,
                        last_edited_at: Time.current)

      lineup.match_players.each do |mp|
        MatchPlayer.create(lineup: new_lineup, real_position: mp.real_position, round_player_id: mp.round_player_id)
      end
    end
  end
end
