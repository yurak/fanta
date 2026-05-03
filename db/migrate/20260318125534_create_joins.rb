class CreateJoins < ActiveRecord::Migration[6.1]
  def change
    create_table :joins do |t|
      t.references :user,       null: false, foreign_key: true
      t.references :tournament, null: false, foreign_key: true
      t.references :team,       null: false, foreign_key: true
      t.integer    :status,     default: 0, null: false
      t.timestamps
    end

    add_index :joins, %i[user_id tournament_id], unique: true
  end
end
