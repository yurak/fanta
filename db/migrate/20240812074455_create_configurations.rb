class CreateConfigurations < ActiveRecord::Migration[6.1]
  def change
    create_table :configurations do |t|
      t.string :provider
      t.text :payload

      t.timestamps
    end
  end
end
