class AddSourceToTournaments < ActiveRecord::Migration[6.1]
  def change
    add_column :tournaments, :source, :integer, default: 0
  end
end
