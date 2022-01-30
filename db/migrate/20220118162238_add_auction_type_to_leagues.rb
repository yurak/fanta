class AddAuctionTypeToLeagues < ActiveRecord::Migration[5.2]
  def change
    add_column :leagues, :auction_type, :integer, null: false, default: 0

    League.all.reload.each(&:live!)
  end
end
