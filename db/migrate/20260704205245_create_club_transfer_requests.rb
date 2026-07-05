class CreateClubTransferRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :club_transfer_requests do |t|
      t.references :player, null: false, foreign_key: true
      t.bigint :tm_transfer_id
      t.integer :old_club_id
      t.string :old_club_name
      t.integer :new_club_id
      t.string :new_club_name
      t.string :tm_club_id
      t.date :start_date
      t.boolean :loan, default: false, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :club_transfer_requests, :status
    add_index :club_transfer_requests, %i[player_id tm_transfer_id], unique: true,
                                                                     where: 'tm_transfer_id IS NOT NULL',
                                                                     name: 'idx_ctr_unique_tm_transfer'
  end
end
