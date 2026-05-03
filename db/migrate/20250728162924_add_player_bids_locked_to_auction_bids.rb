class AddPlayerBidsLockedToAuctionBids < ActiveRecord::Migration[6.1]
  def change
    add_column :auction_bids, :player_bids_locked, :boolean, default: false, null: false
  end
end
