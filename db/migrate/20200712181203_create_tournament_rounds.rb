class CreateTournamentRounds < ActiveRecord::Migration[5.2]
  def change
    create_table :tournament_rounds do |t|
      t.references :tournament, foreign_key: true
      t.references :season, foreign_key: true
      t.integer :number
      t.integer :status, default: 0
      t.datetime :start_time

      t.timestamps
    end
  end
end
