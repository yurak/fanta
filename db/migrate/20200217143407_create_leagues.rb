class CreateLeagues < ActiveRecord::Migration[5.2]
  def change
    create_table :leagues do |t|
      t.string :name
      t.bigint :tournament_id, null: false
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
