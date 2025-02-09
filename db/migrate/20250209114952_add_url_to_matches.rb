class AddUrlToMatches < ActiveRecord::Migration[6.1]
  def change
    add_column :tournament_matches, :page_url, :string, null: false, default: ''
  end
end
