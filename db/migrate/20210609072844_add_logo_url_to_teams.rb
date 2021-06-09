class AddLogoUrlToTeams < ActiveRecord::Migration[5.2]
  def change
    add_column :teams, :logo_url, :string, null: false, default: ''
  end
end
