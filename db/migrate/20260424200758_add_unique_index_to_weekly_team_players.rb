class AddUniqueIndexToWeeklyTeamPlayers < ActiveRecord::Migration[6.1]
  def change
    add_index :weekly_team_players, [:weekly_team_id, :slot_id], unique: true
  end
end
