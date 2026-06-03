class AddReserveClubIdsToClubs < ActiveRecord::Migration[6.1]
  def change
    add_column :clubs, :reserve_club_ids, :text, default: '--- []'
  end
end
