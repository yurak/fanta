class AddTimeZoneAndMailPreferencesToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :time_zone, :string, default: 'UTC', null: false
    add_column :users, :unsubscribe_token, :string
    add_column :users, :subscribed, :boolean, default: true, null: false

    add_index :users, :unsubscribe_token, unique: true
  end
end
