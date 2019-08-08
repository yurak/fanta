class CreateMatches < ActiveRecord::Migration[5.2]
  def change
    create_table :matches do |t|
      t.bigint :tour_id, null: false
      t.bigint :host_id, null: false
      t.bigint :guest_id, null: false

      t.timestamps
    end
  end
end
