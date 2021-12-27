class AddFieldsToAuctionAndClubs < ActiveRecord::Migration[5.2]
  def change
    add_column :auctions, :sales_count, :integer, default: 5, null: false

    add_column :clubs, :tm_name, :string
  end
end
