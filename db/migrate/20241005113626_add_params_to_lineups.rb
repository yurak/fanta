class AddParamsToLineups < ActiveRecord::Migration[6.1]
  def change
    add_column :lineups, :points, :integer, default: 0, null: false
    add_column :lineups, :position, :integer
  end
end
