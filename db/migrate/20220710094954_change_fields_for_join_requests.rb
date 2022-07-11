class ChangeFieldsForJoinRequests < ActiveRecord::Migration[6.1]
  def change
    JoinRequest.all.delete_all

    remove_column :join_requests, :username, :string, default: ""
    remove_column :join_requests, :contact, :string, default: ""
    remove_column :join_requests, :email, :string

    add_reference :join_requests, :user, foreign_key: true
  end
end
