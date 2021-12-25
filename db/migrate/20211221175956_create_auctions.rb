class CreateAuctions < ActiveRecord::Migration[5.2]
  def change
    create_table :auctions do |t|
      t.references :league, foreign_key: true
      t.integer :status, default: 0, null: false
      t.integer :number
      t.datetime :deadline
      t.datetime :event_time

      t.timestamps
    end

    add_reference :transfers, :auction, foreign_key: true
  end
end
