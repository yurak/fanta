class CreatePlayerTeams < ActiveRecord::Migration[5.2]
  def change
    create_table :player_teams do |t|
      t.references :player, foreign_key: true
      t.references :team, foreign_key: true
    end
  end
end
