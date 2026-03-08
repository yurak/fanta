class AddInSquadToRoundPlayers < ActiveRecord::Migration[6.1]
  def change
    add_column :round_players, :in_squad, :boolean, default: false, null: false
  end
end
