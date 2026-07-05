class AddTmHistoryToClubTransfers < ActiveRecord::Migration[8.0]
  def change
    change_table :club_transfers, bulk: true do |t|
      t.bigint  :tm_transfer_id
      t.string  :old_tm_club_id
      t.string  :new_tm_club_id
      t.string  :season
      t.string  :fee
      t.string  :market_value
      t.boolean :upcoming, default: false, null: false
    end

    add_index :club_transfers, %i[player_id tm_transfer_id], unique: true,
                                                             where: 'tm_transfer_id IS NOT NULL',
                                                             name: 'idx_club_transfers_unique_tm_transfer'
  end
end
