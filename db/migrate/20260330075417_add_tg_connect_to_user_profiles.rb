class AddTgConnectToUserProfiles < ActiveRecord::Migration[6.1]
  def change
    add_column :user_profiles, :tg_connect_token, :string
    add_column :user_profiles, :tg_connect_expires_at, :datetime
    add_index :user_profiles, :tg_connect_token, unique: true
  end
end
