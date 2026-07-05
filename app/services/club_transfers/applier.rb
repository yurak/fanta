module ClubTransfers
  class Applier < ApplicationService
    OUTSIDE_CLUB_NAME = 'Outside'.freeze

    def initialize(transfer)
      @transfer = transfer
      @player = transfer.player
    end

    def call
      return :skipped if already_in_new_club?
      return club_change(new_club_id) if db_club?
      return :skipped if in_outside?

      move_to_outside
    end

    private

    def new_club_id
      @transfer.new_club_id
    end

    def already_in_new_club?
      new_club_id && new_club_id == @player.club_id
    end

    def db_club?
      new_club_id && Club.exists?(new_club_id)
    end

    def in_outside?
      @player.club&.name == OUTSIDE_CLUB_NAME
    end

    def move_to_outside
      outside = Club.find_by(name: OUTSIDE_CLUB_NAME)
      return :failed unless outside

      club_change(outside.id)
    end

    def club_change(club_id)
      Players::ClubChanger.call(player: @player, new_club_id: club_id) ? :changed : :failed
    end
  end
end
