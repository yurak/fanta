module ClubTransfers
  class RequestBuilder < ApplicationService
    OUTSIDE_CLUB_NAME = 'Outside'.freeze

    def initialize(player)
      @player = player
    end

    def call
      return nil if deceased?

      transfer = latest_transfer
      return nil unless transfer && needs_request?(transfer)

      existing = existing_request(transfer)
      return create_request(transfer) unless existing
      return nil if up_to_date?(existing, transfer)

      refresh_request(existing, transfer)
    end

    private

    def deceased?
      @player.club&.name == Club::DECEASED
    end

    def latest_transfer
      @player.club_transfers.tm_sourced
             .where(upcoming: false)
             .where(start_date: ..Time.zone.today)
             .order(start_date: :desc, tm_transfer_id: :desc)
             .first
    end

    def needs_request?(transfer)
      return false if same_current_club?(transfer)

      transfer.new_club_id ? true : @player.club&.name != OUTSIDE_CLUB_NAME
    end

    def same_current_club?(transfer)
      return true if transfer.new_club_id && transfer.new_club_id == @player.club_id
      return false if transfer.new_tm_club_id.blank?

      Club.for_tm_id(transfer.new_tm_club_id)&.id == @player.club_id
    end

    def existing_request(transfer)
      ClubTransferRequest.find_by(player_id: @player.id, tm_transfer_id: transfer.tm_transfer_id)
    end

    def up_to_date?(request, transfer)
      request.new_club_id == transfer.new_club_id &&
        (transfer.new_club_id.present? || request.new_club_name == transfer.new_club_name)
    end

    def create_request(transfer)
      ClubTransferRequest.create!(request_attributes(transfer).merge(status: :pending))
    end

    def refresh_request(request, transfer)
      request.update!(request_attributes(transfer).merge(status: :pending))
      request
    end

    def request_attributes(transfer)
      {
        player: @player,
        tm_transfer_id: transfer.tm_transfer_id,
        old_club_id: @player.club_id,
        old_club_name: @player.club&.name,
        new_club_id: transfer.new_club_id,
        new_club_name: transfer.new_club_name,
        tm_club_id: transfer.new_tm_club_id,
        start_date: transfer.start_date,
        loan: transfer.loan
      }
    end
  end
end
