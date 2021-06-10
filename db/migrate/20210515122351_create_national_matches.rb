class CreateNationalMatches < ActiveRecord::Migration[5.2]
  def change
    create_table :national_matches do |t|
      t.references :tournament_round, foreign_key: true
      t.bigint :host_team_id, null: false
      t.bigint :guest_team_id, null: false
      t.integer :host_score
      t.integer :guest_score
      t.string :time, null: false, default: ''
      t.string :date, null: false, default: ''
      t.string :round_name, null: false, default: ''
      t.string :source_match_id, null: false, default: ''

      t.timestamps
    end
  end
end
