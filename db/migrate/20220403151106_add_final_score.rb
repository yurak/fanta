class AddFinalScore < ActiveRecord::Migration[6.1]
  def change
    add_column :round_players, :final_score, :decimal,precision: 4, scale: 2, default: 0
    add_column :lineups, :final_score, :decimal,precision: 4, scale: 2, default: 0
  end
end
