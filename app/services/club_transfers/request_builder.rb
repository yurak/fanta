module ClubTransfers
  class RequestBuilder < ApplicationService
    OUTSIDE_CLUB_NAME = 'Outside'.freeze

    def initialize(player)
      @player = player
    end

    def call
      transfer = latest_transfer
      return nil unless transfer && needs_request?(transfer)
      return nil if request_exists?(transfer)

      create_request(transfer)
    end

    private

    def latest_transfer
      @player.club_transfers.tm_sourced
             .where(upcoming: false)
             .where('start_date <= ?', Time.zone.today)
             .order(start_date: :desc, tm_transfer_id: :desc)
             .first
    end

    def needs_request?(transfer)
      if transfer.new_club_id
        transfer.new_club_id != @player.club_id
      else
        @player.club&.name != OUTSIDE_CLUB_NAME
      end
    end

    def request_exists?(transfer)
      ClubTransferRequest.exists?(player_id: @player.id, tm_transfer_id: transfer.tm_transfer_id)
    end

    def create_request(transfer)
      ClubTransferRequest.create!(
        player: @player,
        tm_transfer_id: transfer.tm_transfer_id,
        old_club_id: @player.club_id,
        old_club_name: @player.club&.name,
        new_club_id: transfer.new_club_id,
        new_club_name: transfer.new_club_name,
        tm_club_id: transfer.new_tm_club_id,
        start_date: transfer.start_date,
        loan: transfer.loan,
        status: :pending
      )
    end
  end
end
