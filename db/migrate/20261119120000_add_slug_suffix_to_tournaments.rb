class AddSlugSuffixToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :slug_suffix, :string, default: '', null: false
  end
end
