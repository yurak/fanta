class CreateWeeklyTeams < ActiveRecord::Migration[6.1]
  def change
    create_table :weekly_teams do |t|
      t.integer :number
      t.string :mode
      t.text :round_ids
      t.references :team_module, null: false, foreign_key: true
      t.references :season, null: false, foreign_key: true

      t.timestamps
    end
  end
end
