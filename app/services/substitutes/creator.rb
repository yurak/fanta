module Substitutes
  class Creator < ApplicationService
    attr_reader :in_mp_id, :out_mp_id

    def initialize(out_mp_id:, in_mp_id:)
      @in_mp_id = in_mp_id
      @out_mp_id = out_mp_id
    end

    def call
      return false unless main_match_player && reserve_match_player

      return false if (main_match_player.available_positions & reserve_match_player.player.position_names).empty?

      subs_transaction
    end

    private

    def subs_transaction
      MatchPlayer.transaction do
        new_round_player = reserve_match_player.round_player
        create_substitute
        reserve_match_player.update(round_player_id: main_match_player.round_player_id,
                                    subs_status: :get_out,
                                    position_malus: 0)
        main_match_player.update(round_player_id: new_round_player.id,
                                 subs_status: :get_in,
                                 position_malus: 0)
      end
    end

    def create_substitute
      Substitute.create(
        main_mp: main_match_player,
        reserve_mp: reserve_match_player,
        out_rp: main_match_player.round_player,
        in_rp: reserve_match_player.round_player
      )
    end

    def main_match_player
      @main_match_player ||= match_player(out_mp_id)
    end

    def reserve_match_player
      @reserve_match_player ||= match_player(in_mp_id)
    end

    def match_player(id)
      MatchPlayer.find_by(id: id)
    end
  end
end
