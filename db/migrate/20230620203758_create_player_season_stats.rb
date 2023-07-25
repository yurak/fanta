class CreatePlayerSeasonStats < ActiveRecord::Migration[6.1]
  def change
    create_table :player_season_stats do |t|
      t.integer :player_id, null: false
      t.integer :season_id, null: false
      t.integer :club_id, null: false
      t.integer :tournament_id, null: false

      t.integer :played_matches, default: 0, null: false
      t.decimal :score, precision: 10, scale: 2, default: 0, null: false
      t.decimal :final_score, precision: 10, scale: 2, default: 0, null: false
      t.integer :goals, default: 0, null: false
      t.integer :assists, default: 0, null: false
      t.integer :scored_penalty, default: 0, null: false
      t.integer :failed_penalty, default: 0, null: false
      t.integer :cleansheet, default: 0, null: false
      t.integer :missed_goals, default: 0, null: false
      t.integer :missed_penalty, default: 0, null: false
      t.integer :caught_penalty, default: 0, null: false
      t.integer :saves, default: 0, null: false
      t.integer :yellow_card, default: 0, null: false
      t.integer :red_card, default: 0, null: false
      t.integer :own_goals, default: 0, null: false
      t.integer :conceded_penalty, default: 0, null: false
      t.integer :penalties_won, default: 0, null: false
      t.integer :played_minutes, default: 0, null: false
      t.integer :position_price, default: 1, null: false
      t.string :position1
      t.string :position2
      t.string :position3

      t.timestamps
    end

    add_column :round_players, :club_id, :integer
  end
end
