class RemoveContractExpiresOnFromClubTransfers < ActiveRecord::Migration[8.0]
  def change
    remove_column :club_transfers, :contract_expires_on, :date
  end
end
