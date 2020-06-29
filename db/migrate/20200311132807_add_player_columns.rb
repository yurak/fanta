class AddPlayerColumns < ActiveRecord::Migration[5.2]
  def change
    connection.execute('PRAGMA defer_foreign_keys = ON')
    connection.execute('PRAGMA foreign_keys = OFF')
    remove_column :players, :team_id
    connection.execute('PRAGMA foreign_keys = ON')
    connection.execute('PRAGMA defer_foreign_keys = OFF')

    add_column :players, :first_name, :string
    add_column :players, :nationality, :string
    add_column :players, :tm_url, :string
  end
end
