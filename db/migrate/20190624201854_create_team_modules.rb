class CreateTeamModules < ActiveRecord::Migration[5.2]
  def change
    create_table :team_modules do |t|
      t.string :name

      t.timestamps
    end
  end
end
