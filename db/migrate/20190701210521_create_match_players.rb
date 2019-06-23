class CreateMatchPlayers < ActiveRecord::Migration[5.2]
  def change
    create_table :match_players do |t|
      t.decimal :score
      t.integer :player_id
      t.integer :lineup_id

      t.timestamps
    end
  end
end
