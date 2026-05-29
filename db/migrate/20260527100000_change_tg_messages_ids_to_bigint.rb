class ChangeTgMessagesIdsToBigint < ActiveRecord::Migration[6.1]
  def up
    change_column :tg_messages, :update_id, :bigint, null: false
    change_column :tg_messages, :message_id, :bigint
    change_column :tg_messages, :chat_id, :bigint
  end

  def down
    change_column :tg_messages, :update_id, :integer, null: false
    change_column :tg_messages, :message_id, :integer
    change_column :tg_messages, :chat_id, :integer
  end
end