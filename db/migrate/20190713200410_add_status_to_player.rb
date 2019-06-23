class AddStatusToPlayer < ActiveRecord::Migration[5.2]
  def change
    add_column :players, :status, :integer, default: 0
  end
end
