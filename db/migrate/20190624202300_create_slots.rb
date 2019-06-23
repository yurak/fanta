class CreateSlots < ActiveRecord::Migration[5.2]
  def change
    create_table :slots do |t|
      t.integer :number
      t.string :position
      t.integer :team_module_id

      t.timestamps
    end
  end
end
