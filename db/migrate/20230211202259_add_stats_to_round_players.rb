class AddStatsToRoundPlayers < ActiveRecord::Migration[6.1]
  def change
    add_column :round_players, :saves, :integer, default: 0, null: false
    add_column :round_players, :conceded_penalty, :integer, default: 0, null: false
    add_column :round_players, :penalties_won, :integer, default: 0, null: false
  end
end
