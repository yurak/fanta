class AddRelations < ActiveRecord::Migration[5.2]
  def change
    add_reference :links, :league, foreign_key: true
    add_reference :teams, :league, foreign_key: true
    add_reference :tours, :league, foreign_key: true
    add_reference :clubs, :tournament, foreign_key: true
  end
end
