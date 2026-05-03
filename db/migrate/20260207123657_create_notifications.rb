class CreateNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :notifications do |t|
      t.references :team, null: false, foreign_key: true
      t.references :notifiable, polymorphic: true, null: false
      t.integer :kind, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.integer :priority, null: false, default: 1

      t.datetime :sent_at
      t.string :error_message

      t.timestamps
    end

    add_index :notifications, :status
    add_index :notifications, [:notifiable_type, :notifiable_id, :status], name: "index_notifications_on_notifiable_and_status"
    add_index :notifications, [:status, :priority, :id], name: "index_notifications_on_status_and_priority"
  end
end
