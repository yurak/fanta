class AddAuctionNumberToLeagues < ActiveRecord::Migration[6.1]
  def change
    add_column :leagues, :auction_number, :integer, default: 5
  end
end
