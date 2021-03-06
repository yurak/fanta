class CreateJoinRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :join_requests do |t|
      t.string :username, null: false, default: ""
      t.string :contact, null: false, default: ""
      t.string :email
      t.string :leagues
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
