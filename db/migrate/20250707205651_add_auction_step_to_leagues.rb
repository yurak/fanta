class AddAuctionStepToLeagues < ActiveRecord::Migration[6.1]
  def change
    add_column :leagues, :auction_step, :integer, default: 11, null: false
  end
end
