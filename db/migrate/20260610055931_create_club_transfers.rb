class CreateClubTransfers < ActiveRecord::Migration[6.1]
  def change
    create_table :club_transfers do |t|
      t.references :player, null: false, foreign_key: true
      t.references :old_club, foreign_key: { to_table: :clubs }
      t.references :new_club, foreign_key: { to_table: :clubs }
      t.string :old_club_name
      t.string :new_club_name
      t.date :start_date, null: false
      t.boolean :loan, null: false, default: false
      t.date :contract_expires_on

      t.timestamps
    end

    add_index :club_transfers, %i[player_id new_club_id start_date],
              unique: true, where: 'new_club_id IS NOT NULL',
              name: 'idx_club_transfers_unique_with_club'
    add_index :club_transfers, %i[player_id new_club_name start_date],
              unique: true, where: 'new_club_id IS NULL',
              name: 'idx_club_transfers_unique_without_club'
  end
end
