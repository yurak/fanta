class CreateTgMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :tg_messages do |t|
      t.integer :update_id, null: false
      t.integer :message_id
      t.integer :chat_id
      t.string :text
      t.string :username
      t.string :first_name
      t.string :last_name
      t.timestamp :date
      t.string :full_data

      t.timestamps
    end
  end
end
