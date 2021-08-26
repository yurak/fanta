class AddTransferStatusToPlayerTeams < ActiveRecord::Migration[5.2]
  def change
    add_column :player_teams, :transfer_status, :integer, default: 0
    add_column :leagues, :transfer_status, :integer, default: 0
  end
end
