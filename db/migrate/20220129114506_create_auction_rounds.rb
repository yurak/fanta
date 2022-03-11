class CreateAuctionRounds < ActiveRecord::Migration[5.2]
  def change
    create_table :auction_rounds do |t|
      t.references :auction, foreign_key: true
      t.integer :number
      t.datetime :deadline

      t.timestamps
    end
  end
end
