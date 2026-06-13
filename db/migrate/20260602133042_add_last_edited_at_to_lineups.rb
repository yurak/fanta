class AddLastEditedAtToLineups < ActiveRecord::Migration[6.1]
  def change
    add_column :lineups, :last_edited_at, :datetime
    execute 'UPDATE lineups SET last_edited_at = created_at'
  end
end
