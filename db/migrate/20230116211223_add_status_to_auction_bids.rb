class AddStatusToAuctionBids < ActiveRecord::Migration[6.1]
  def change
    add_column :auction_bids, :status, :integer, default: 0

    AuctionBid.update_all(status: :processed)
  end
end
