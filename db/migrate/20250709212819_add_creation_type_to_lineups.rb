class AddCreationTypeToLineups < ActiveRecord::Migration[6.1]
  def change
    add_column :lineups, :creation_type, :integer, default: 0, null: false
  end
end
