class UpdateTournamentMatchesParams < ActiveRecord::Migration[5.2]
  def change
    drop_table :tournament_matches

    create_table :tournament_matches do |t|
      t.references :tournament_round, foreign_key: true
      t.bigint :host_club_id, null: false
      t.bigint :guest_club_id, null: false
      t.integer :host_score
      t.integer :guest_score

      t.timestamps
    end
  end
end
