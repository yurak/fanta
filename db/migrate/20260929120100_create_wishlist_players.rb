class CreateWishlistPlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :wishlist_players do |t|
      t.references :wishlist, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true

      t.timestamps
    end

    add_index :wishlist_players, %i[wishlist_id player_id], unique: true
  end
end
