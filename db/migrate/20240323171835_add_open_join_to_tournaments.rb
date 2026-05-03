class AddOpenJoinToTournaments < ActiveRecord::Migration[6.1]
  def change
    add_column :tournaments, :open_join, :boolean, null: false, default: true
  end
end
