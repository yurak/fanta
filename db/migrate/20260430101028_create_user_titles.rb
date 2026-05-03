class CreateUserTitles < ActiveRecord::Migration[6.1]
  def change
    create_table :user_titles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tournament, null: true, foreign_key: true
      t.references :result, null: true, foreign_key: true
      t.integer :championship_number, null: false
      t.string :season

      t.timestamps
    end
  end
end
