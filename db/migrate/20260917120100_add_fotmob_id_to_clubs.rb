class AddFotmobIdToClubs < ActiveRecord::Migration[8.0]
  def change
    add_column :clubs, :fotmob_id, :bigint
    add_index :clubs, :fotmob_id, unique: true
  end
end
