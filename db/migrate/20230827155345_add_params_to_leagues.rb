class AddParamsToLeagues < ActiveRecord::Migration[6.1]
  def change
    add_column :leagues, :promotion, :integer, default: 0, null: false
    add_column :leagues, :relegation, :integer, default: 0, null: false
  end
end
