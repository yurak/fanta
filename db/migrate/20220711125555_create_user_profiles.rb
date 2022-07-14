class CreateUserProfiles < ActiveRecord::Migration[6.1]
  def change
    create_table :user_profiles do |t|
      t.integer :user_id
      t.integer :tg_chat_id
      t.string :tg_name
      t.boolean :bot_enabled, default: false

      t.timestamps
    end
  end
end
