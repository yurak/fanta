class AddSubsStatusToMatchPlayers < ActiveRecord::Migration[5.2]
  def change
    add_column :match_players, :subs_status, :integer, null: false, default: 0
  end
end
