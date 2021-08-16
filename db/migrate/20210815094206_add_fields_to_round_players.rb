class AddFieldsToRoundPlayers < ActiveRecord::Migration[5.2]
  def change
    add_column :round_players, :manual_lock, :boolean, default: false
    add_column :round_players, :played_minutes, :integer, default: 0, null: false
  end
end
