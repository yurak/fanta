class AddCsmToLeague < ActiveRecord::Migration[5.2]
  def change
    add_column :leagues, :cleansheet_m, :boolean, null: false, default: true
  end
end
