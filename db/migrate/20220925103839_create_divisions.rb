class CreateDivisions < ActiveRecord::Migration[6.1]
  def change
    create_table :divisions do |t|
      t.string :level
      t.integer :number

      t.timestamps
    end

    add_column :leagues, :division_id, :integer
    add_column :player_teams, :created_at, :datetime, null: false, default: Time.zone.now
    add_column :player_teams, :updated_at, :datetime, null: false, default: Time.zone.now
    add_column :tournaments, :short_name, :string
  end
end
