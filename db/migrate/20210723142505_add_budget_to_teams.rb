class AddBudgetToTeams < ActiveRecord::Migration[5.2]
  def change
    add_column :teams, :budget, :integer, default: 260
  end
end
