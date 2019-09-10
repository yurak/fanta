class CreateResults < ActiveRecord::Migration[5.2]
  def change
    create_table :results do |t|
      t.belongs_to :team
      t.integer :points, default: 0, null: false
      t.integer :scored_goals, default: 0, null: false
      t.integer :missed_goals, default: 0, null: false
      t.integer :wins, default: 0, null: false
      t.integer :draws, default: 0, null: false
      t.integer :loses, default: 0, null: false

      t.timestamps
    end
  end
end
