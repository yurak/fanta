class AddStatusToAuctionRounds < ActiveRecord::Migration[5.2]
  def change
    add_column :auction_rounds, :status, :integer, default: 0
  end
end
