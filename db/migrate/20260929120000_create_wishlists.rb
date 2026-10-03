class CreateWishlists < ActiveRecord::Migration[8.0]
  def change
    create_table :wishlists do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tournament, null: false, foreign_key: true
      t.references :season, null: false, foreign_key: true
      t.boolean :shared, null: false, default: false

      t.timestamps
    end

    add_index :wishlists, %i[user_id tournament_id season_id], unique: true
  end
end
