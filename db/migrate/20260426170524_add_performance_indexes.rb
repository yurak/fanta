class AddPerformanceIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :match_players, :lineup_id
    add_index :lineups, :tour_id
    add_index :lineups, :team_id
    add_index :lineups, [:team_id, :tour_id], unique: true
  end
end
