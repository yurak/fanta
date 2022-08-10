class RemoveTeamsUniqueIndex < ActiveRecord::Migration[6.1]
  def change
    remove_index :teams, :name
    remove_index :teams, :code
  end
end
