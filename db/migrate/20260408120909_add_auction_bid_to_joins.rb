class AddAuctionBidToJoins < ActiveRecord::Migration[6.1]
  def up
    add_reference :joins, :auction_bid, null: true, foreign_key: true

    Join.find_each do |join|
      bid = join.team.auction_bids.min_by(&:id)
      join.update_column(:auction_bid_id, bid.id) if bid
    end

    change_column_null :joins, :auction_bid_id, false
  end

  def down
    remove_reference :joins, :auction_bid, foreign_key: true
  end
end
