class AddUniqueIndexToAuctionBidsRoundTeam < ActiveRecord::Migration[8.0]
  def change
    add_index :auction_bids, %i[auction_round_id team_id],
              unique: true,
              where: 'auction_round_id IS NOT NULL',
              name: 'index_auction_bids_on_round_and_team_unique'
  end
end
