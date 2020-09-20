class AddParamsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :name, :string, null: false, default: ''
    add_column :users, :active_team_id, :integer
    add_column :users, :notifications, :boolean, null: false, default: false
    add_column :users, :avatar, :string, null: false, default: '1'
  end
end
