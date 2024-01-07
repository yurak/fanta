class AddFinalGoalsToLineups < ActiveRecord::Migration[6.1]
  def change
    add_column :lineups, :final_goals, :integer
  end
end
