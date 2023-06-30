class AddBasicToAuctionRounds < ActiveRecord::Migration[6.1]
  def change
    add_column :auction_rounds, :basic, :boolean, default: false, null: false
  end
end
