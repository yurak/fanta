class AddTransferSlotsToTeams < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :transfer_slots, :integer, default: 0
  end
end
