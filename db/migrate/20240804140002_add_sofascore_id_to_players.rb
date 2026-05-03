class AddSofascoreIdToPlayers < ActiveRecord::Migration[6.1]
  def change
    add_column :players, :sofascore_id, :integer

    add_index :players, :sofascore_id, unique: true
  end
end
