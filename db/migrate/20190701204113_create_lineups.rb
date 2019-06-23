class CreateLineups < ActiveRecord::Migration[5.2]
  def change
    create_table :lineups do |t|
      t.integer :team_id
      t.integer :team_module_id

      t.timestamps
    end
  end
end
