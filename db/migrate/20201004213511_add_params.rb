class AddParams < ActiveRecord::Migration[5.2]
  def change
    add_column :leagues, :recount_goals, :boolean, null: false, default: false
  end
end
