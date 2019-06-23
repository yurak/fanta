class AddTourIdTiLineup < ActiveRecord::Migration[5.2]
  def change
    add_column :lineups, :tour_id, :integer
  end
end
