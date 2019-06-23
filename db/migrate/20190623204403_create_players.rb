class CreatePlayers < ActiveRecord::Migration[5.2]
  def change
    create_table :players do |t|
      t.string :name
      t.integer :team_id
      t.integer :club_id

      t.timestamps
    end
  end
end
