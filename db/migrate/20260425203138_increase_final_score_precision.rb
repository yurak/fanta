class IncreaseFinalScorePrecision < ActiveRecord::Migration[6.1]
  def change
    change_column :lineups, :final_score, :decimal, precision: 6, scale: 2, default: 0.0
    change_column :round_players, :final_score, :decimal, precision: 6, scale: 2, default: 0.0
  end
end
