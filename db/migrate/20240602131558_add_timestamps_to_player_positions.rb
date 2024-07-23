class AddTimestampsToPlayerPositions < ActiveRecord::Migration[6.1]
  def change
    add_column :player_positions, :created_at, :timestamp
    add_column :player_positions, :updated_at, :timestamp
  end
end
