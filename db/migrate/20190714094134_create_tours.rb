class CreateTours < ActiveRecord::Migration[5.2]
  def change
    create_table :tours do |t|
      t.integer :number
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
