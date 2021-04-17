class AddUniqueIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :clubs, :code, unique: true
    add_index :clubs, :name, unique: true

    add_index :leagues, :name, unique: true

    add_index :players, [:name, :first_name], unique: true

    add_index :positions, :name, unique: true

    add_index :seasons, :end_year, unique: true
    add_index :seasons, :start_year, unique: true

    add_index :teams, :code, unique: true
    add_index :teams, :name, unique: true

    add_index :team_modules, :name, unique: true

    add_index :tournaments, :code, unique: true
  end
end
