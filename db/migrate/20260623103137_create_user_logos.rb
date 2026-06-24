class CreateUserLogos < ActiveRecord::Migration[8.0]
  def change
    create_table :user_logos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :url, null: false
      t.integer :status, null: false, default: 0
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :user_logos, :status
    add_index :user_logos, :deleted_at
  end
end
