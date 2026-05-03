class AddChampionNumberToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :champion_number, :integer
  end
end
