class CreateTournamentMatches < ActiveRecord::Migration[5.2]
  def change
    create_table :tournament_matches do |t|
      t.references :tournament_round, foreign_key: true
      t.references :host_club, foreign_key: true
      t.references :guest_club, foreign_key: true
      t.integer :host_score
      t.integer :guest_score

      t.timestamps
    end
  end
end
