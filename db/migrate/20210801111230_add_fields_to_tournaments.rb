class AddFieldsToTournaments < ActiveRecord::Migration[5.2]
  def change
    add_column :tournaments, :lineup_first_goal, :integer, null: false, default: 72
    add_column :tournaments, :lineup_increment, :integer, null: false, default: 7
  end
end
