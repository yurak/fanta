class PlayerPoisitons < ActiveRecord::Migration[5.2]
  def change
    create_table :players_positions, id: false do |t|
      t.integer :player_id
      t.integer :position_id
    end
  end
end
