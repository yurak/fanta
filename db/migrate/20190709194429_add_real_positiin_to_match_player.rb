class AddRealPositiinToMatchPlayer < ActiveRecord::Migration[5.2]
  def change
    add_column :match_players, :real_position, :string
  end
end
