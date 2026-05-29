class AddHumanNameToPositions < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :ital_pos_naming, :boolean, null: false, default: false
    add_column :positions, :human_name, :string, null: false, default: ''

    remove_column :users, :summer_balance, :decimal
    remove_column :players, :status, :integer
    remove_column :tournament_rounds, :start_time, :datetime
  end
end
