class CreatePlayerBids < ActiveRecord::Migration[5.2]
  def change
    create_table :player_bids do |t|
      t.references :auction_bid, foreign_key: true
      t.references :player, foreign_key: true
      t.integer :price, default: 1, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
