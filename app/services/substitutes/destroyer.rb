module Substitutes
  class Destroyer < ApplicationService
    attr_reader :subs_id

    def initialize(subs_id)
      @subs_id = subs_id
    end

    def call
      return false unless substitute

      subs_transaction
    end

    private

    def subs_transaction
      MatchPlayer.transaction do
        main_positions = substitute.main_mp.player_positions
        reserve_positions = substitute.reserve_mp.player_positions
        substitute.main_mp.update(round_player_id: substitute.out_rp_id,
                                  subs_status: :initial,
                                  position_malus: 0,
                                  player_positions: reserve_positions)
        substitute.reserve_mp.update(round_player_id: substitute.in_rp_id,
                                     subs_status: :initial,
                                     position_malus: 0,
                                     player_positions: main_positions)
        substitute.destroy
      end
    end

    def substitute
      return @substitute if defined?(@substitute)

      @substitute = Substitute.find_by(id: subs_id)
    end
  end
end
