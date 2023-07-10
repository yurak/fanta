class AddParamsToTournaments < ActiveRecord::Migration[6.1]
  def change
    add_column :tournaments, :source_id, :integer
  end
end
