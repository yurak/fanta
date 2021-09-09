class AddCloningToLeagues < ActiveRecord::Migration[5.2]
  def change
    add_column :leagues, :cloning_status, :integer, null: false, default: 0
  end
end
