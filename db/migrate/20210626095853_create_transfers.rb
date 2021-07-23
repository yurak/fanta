class CreateTransfers < ActiveRecord::Migration[5.2]
  def change
    create_table :transfers do |t|
      t.references :player, foreign_key: true
      t.references :team, foreign_key: true
      t.references :league, foreign_key: true
      t.integer :price, default: 1, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    remove_index :players, name: "index_players_on_name_and_first_name"
    add_index :players, [:name, :first_name, :tm_url], unique: true
  end
end
