module ClubTransfers
  class HistoryImporter < ApplicationService
    def initialize(player)
      @player = player
      @club_cache = {}
    end

    def call
      return 0 unless @player&.tm_id

      imported = 0
      Players::Transfermarkt::TransferHistoryParser.call(@player.tm_id).each do |tr|
        imported += 1 if save_transfer(tr)
      end
      imported
    end

    private

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

      @club_cache[tm_club_id] = find_club(tm_club_id)&.id
    end

    def find_club(tm_club_id)
      Club.where('tm_url LIKE ?', "%/#{tm_club_id}").first ||
        Club.where.not(reserve_club_ids: ['--- []', nil])
            .find { |c| c.reserve_club_ids.include?(tm_club_id) }
    end
  end
end
