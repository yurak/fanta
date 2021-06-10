class AddTotalScoreToResults < ActiveRecord::Migration[5.2]
  def change
    add_column :results, :total_score, :decimal,  null: false, default: 0.0
  end
end
