class AddColorToClubs < ActiveRecord::Migration[5.2]
  def change
    add_column :clubs, :color, :string, null: false, default: '181715'
  end
end
