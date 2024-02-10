class AddReserveClubsToClubs < ActiveRecord::Migration[6.1]
  def change
    add_column :clubs, :reserve_clubs, :text, default: [].to_yaml
  end
end
