class AddAttemptsToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_column :notifications, :attempts, :integer, default: 0, null: false
  end
end
