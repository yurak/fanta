class AddFullNameToClubs < ActiveRecord::Migration[5.2]
  def change
    add_column :clubs, :full_name, :string, null: false, default: ''
  end
end
