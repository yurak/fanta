class DropJoinRequests < ActiveRecord::Migration[6.1]
  def change
    drop_table :join_requests
  end
end