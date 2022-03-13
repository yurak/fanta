class AddTmUrlToClubs < ActiveRecord::Migration[5.2]
  def change
    add_column :clubs, :tm_url, :string
  end
end
