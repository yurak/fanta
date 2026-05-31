class AddPlayerPositionsToMatchPlayers < ActiveRecord::Migration[6.1]
  def change
    add_column :match_players, :player_positions, :string
  end
end
