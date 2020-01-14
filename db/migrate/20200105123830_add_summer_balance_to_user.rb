class AddSummerBalanceToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :summer_balance, :decimal, default: 0.0
  end
end
