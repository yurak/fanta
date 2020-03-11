class AddIdToPlayersPositions < ActiveRecord::Migration[5.2]
  def change
    rename_table :players_positions, :player_positions
    add_column :player_positions, :id, :primary_key
    add_index :player_positions, %I(player_id position_id), name: :player_position
  end
end
