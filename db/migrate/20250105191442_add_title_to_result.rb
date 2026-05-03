class AddTitleToResult < ActiveRecord::Migration[6.1]
  def change
    add_column :results, :title, :boolean, default: false, null: false
    add_column :results, :position, :integer
    add_column :results, :secondary_position, :integer

    add_column :tournaments, :mode, :integer, default: 0, null: false
  end
end
