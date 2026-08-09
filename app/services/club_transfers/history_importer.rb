module ClubTransfers
  class HistoryImporter < ApplicationService
    def initialize(player)
      @player = player
      @club_cache = {}
    end

    def call
      return 0 unless @player&.tm_id

      transfers = Players::Transfermarkt::TransferHistoryParser.call(@player.tm_id)
      return 0 if transfers.blank?

      imported = transfers.count { |tr| save_transfer(tr) }
      prune_stale(transfers)
      imported
    end

    private

    def prune_stale(transfers)
      tm_ids = transfers.pluck(:tm_transfer_id).compact
      return if tm_ids.empty?

      stale = @player.club_transfers.tm_sourced.where.not(tm_transfer_id: tm_ids)
      stale_tm_ids = stale.pluck(:tm_transfer_id)
      return if stale_tm_ids.empty?

      ClubTransferRequest.pending.where(player_id: @player.id, tm_transfer_id: stale_tm_ids).delete_all
      stale.delete_all
    end

    def save_transfer(transfer)
      return false if transfer[:tm_transfer_id].blank? || transfer[:start_date].blank?

      record = ClubTransfer.find_or_initialize_by(player_id: @player.id, tm_transfer_id: transfer[:tm_transfer_id])
      record.assign_attributes(attributes_for(transfer))
      record.save
    rescue ActiveRecord::RecordNotUnique
      false
    end

    def attributes_for(transfer)
      {
        old_club_name: transfer[:old_club_name],
        old_tm_club_id: transfer[:old_tm_club_id],
        old_club_id: resolve_club_id(transfer[:old_tm_club_id]),
        new_club_name: transfer[:new_club_name],
        new_tm_club_id: transfer[:new_tm_club_id],
        new_club_id: resolve_club_id(transfer[:new_tm_club_id]),
        start_date: transfer[:start_date],
        loan: transfer[:loan],
        season: transfer[:season],
        fee: transfer[:fee],
        market_value: transfer[:market_value],
        upcoming: transfer[:upcoming]
      }
    end

    def resolve_club_id(tm_club_id)
      return nil if tm_club_id.blank?
      return @club_cache[tm_club_id] if @club_cache.key?(tm_club_id)

      @club_cache[tm_club_id] = Club.for_tm_id(tm_club_id)&.id
    end
  end
end
