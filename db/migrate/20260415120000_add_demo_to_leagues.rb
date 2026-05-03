class AddDemoToLeagues < ActiveRecord::Migration[6.1]
  def change
    add_column :leagues, :demo, :boolean, default: false, null: false
  end
end
