class AddParamsToPlayers < ActiveRecord::Migration[5.2]
  def change
    add_column :players, :birth_date, :string, null: false, default: ''
    add_column :players, :height, :integer
    add_column :players, :number, :integer
    add_column :players, :tm_price, :integer
  end
end
