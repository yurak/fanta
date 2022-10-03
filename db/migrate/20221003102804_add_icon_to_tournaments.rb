class AddIconToTournaments < ActiveRecord::Migration[6.1]
  def change
    add_column :tournaments, :icon, :string

    remove_column :player_teams, :created_at, :datetime, null: false, default: Time.zone.now
    remove_column :player_teams, :updated_at, :datetime, null: false, default: Time.zone.now
    add_column :player_teams, :created_at, :timestamp
    add_column :player_teams, :updated_at, :timestamp
  end
end
