class AddTournamentsToLinks < ActiveRecord::Migration[5.2]
  def change
    add_reference :links, :tournament, foreign_key: true

    remove_column :links, :league_id
  end
end
