class AddPenaltyPointsToResults < ActiveRecord::Migration[6.1]
  def change
    add_column :results, :penalty_points, :integer, default: 0, null: false
  end
end
