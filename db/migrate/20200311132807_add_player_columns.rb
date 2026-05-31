class AddPlayerColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :players, :team_id
    add_column :players, :first_name, :string
    add_column :players, :nationality, :string
    add_column :players, :tm_url, :string
  end
end
