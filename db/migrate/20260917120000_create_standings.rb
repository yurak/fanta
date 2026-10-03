class CreateStandings < ActiveRecord::Migration[8.0]
  def change
    create_table :standings do |t|
      results(t)
      t.references :tournament, null: false, foreign_key: true
      t.references :season, null: false, foreign_key: true
      t.references :club, foreign_key: true
      t.bigint :fotmob_team_id
      t.string :team_name, null: false, default: ''
      t.integer :position, null: false
      t.string :zone_color, null: false, default: ''

      t.timestamps
    end

    add_index :standings, %i[tournament_id season_id position], unique: true,
                                                                name: 'index_standings_on_tournament_season_position'
  end

  def results(table)
    %i[played wins draws losses goals_for goals_against points].each do |column|
      table.integer column, null: false, default: 0
    end
  end
end
