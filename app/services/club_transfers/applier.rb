module ClubTransfers
  # Applies a proposed club transfer (a ClubTransferRequest or any object exposing the
  # same fields) using the same rules as the club_transfers:create_and_apply task:
  #   - new club in our DB       → real change via Players::ClubChanger
  #   - player already "Outside", new club not in DB → just record the transfer
  #   - real club → club not in DB → move to "Outside", keep the real club name in the record
  # Returns :changed, :created, :skipped or :failed.
  class Applier < ApplicationService
    OUTSIDE_CLUB_NAME = 'Outside'.freeze

    def initialize(transfer)
      @transfer = transfer
      @player = transfer.player
    end

    def call
      return :skipped if already_in_new_club?
      return club_change(new_club_id) if db_club?
      return move_to_outside unless in_outside?

      record_only
      :created
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

      club_change(outside.id, new_club_name: @transfer.new_club_name)
    end

    def club_change(club_id, new_club_name: nil)
      changed = Players::ClubChanger.call(
        player: @player,
        new_club_id: club_id,
        start_date: @transfer.start_date,
        contract_expires_on: @transfer.contract_expires_on,
        loan: @transfer.loan,
        new_club_name: new_club_name
      )

      changed ? :changed : :failed
    end

    def record_only
      ClubTransfer.create!(
        player: @player,
        old_club_id: @transfer.old_club_id,
        old_club_name: @transfer.old_club_name,
        new_club_id: nil,
        new_club_name: @transfer.new_club_name,
        start_date: @transfer.start_date,
        contract_expires_on: @transfer.contract_expires_on,
        loan: @transfer.loan
      )
    end
  end
end
