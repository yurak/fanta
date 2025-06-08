class AddBaseDateToAuctions < ActiveRecord::Migration[6.1]
  def change
    add_column :auctions, :base_date, :string
  end
end
