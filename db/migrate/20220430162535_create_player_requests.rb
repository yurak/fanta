class CreatePlayerRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :player_requests do |t|
      t.references :player, foreign_key: true
      t.references :user, foreign_key: true
      t.string :positions
      t.string :comment

      t.timestamps
    end
  end
end
