class AddBestLineupToResults < ActiveRecord::Migration[6.1]
  def change
    add_column :results, :best_lineup, :decimal,  null: false, default: 0.0
  end
end
