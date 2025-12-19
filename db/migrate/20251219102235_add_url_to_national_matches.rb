class AddUrlToNationalMatches < ActiveRecord::Migration[6.1]
  def change
    add_column :national_matches, :page_url, :string, null: false, default: ''
  end
end
