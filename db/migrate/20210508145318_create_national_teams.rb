class CreateNationalTeams < ActiveRecord::Migration[5.2]
  def change
    create_table :national_teams do |t|
      t.string :code
      t.references :tournament, foreign_key: true

      t.timestamps
    end

    add_reference :players, :national_team, foreign_key: true

    add_index :national_teams, :code, unique: true

    Tournament.find_or_create_by(
      name: 'Euro 2020',
      code: 'euro',
      source_calendar_url: 'https://www.fotmob.com/leagues?id=50&tab=matches&type=league'
    )

    NationalTeams::Creator.call
  end
end
