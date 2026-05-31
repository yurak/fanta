class AddJoinFieldsToLeagues < ActiveRecord::Migration[6.1]
  def change
    add_column :leagues, :join_code, :string
    add_column :leagues, :open_for_join, :boolean, null: false, default: false
    add_column :leagues, :default_for_join, :boolean, null: false, default: false
    add_index :leagues, :join_code, unique: true
  end
end
