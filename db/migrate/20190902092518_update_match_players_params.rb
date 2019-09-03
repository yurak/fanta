class UpdateMatchPlayersParams < ActiveRecord::Migration[5.2]
  def change
    rename_column :match_players, :assits, :assists
    rename_column :match_players, :malus, :position_malus

    change_column :match_players, :score, :decimal, default: 0

    add_column :match_players, :missed_penalty, :decimal, default: 0
    add_column :match_players, :scored_penalty, :decimal, default: 0
    add_column :match_players, :caught_penalty, :decimal, default: 0
    add_column :match_players, :failed_penalty, :decimal, default: 0
    add_column :match_players, :own_goals, :decimal, default: 0
  end
end
