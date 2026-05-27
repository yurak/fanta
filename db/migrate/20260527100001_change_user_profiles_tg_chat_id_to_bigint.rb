class ChangeUserProfilesTgChatIdToBigint < ActiveRecord::Migration[6.1]
  def up
    change_column :user_profiles, :tg_chat_id, :bigint
  end

  def down
    change_column :user_profiles, :tg_chat_id, :integer
  end
end