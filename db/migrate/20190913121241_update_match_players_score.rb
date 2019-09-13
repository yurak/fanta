class UpdateMatchPlayersScore < ActiveRecord::Migration[5.2]
  def change
    change_column :match_players, :score, :decimal, default: 0, precision: 4, scale: 2
  end
end
