class CreateWeeklyTeamPlayers < ActiveRecord::Migration[6.1]
  def change
    create_table :weekly_team_players do |t|
      t.references :weekly_team, null: false, foreign_key: true
      t.references :slot, null: false, foreign_key: true
      t.references :round_player, null: false, foreign_key: true
      t.decimal :total

      t.timestamps
    end
  end
end
