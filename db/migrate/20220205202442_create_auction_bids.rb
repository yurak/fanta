class CreateAuctionBids < ActiveRecord::Migration[5.2]
  def change
    create_table :auction_bids do |t|
      t.references :auction_round, foreign_key: true
      t.references :team, foreign_key: true

      t.timestamps
    end
  end
end
