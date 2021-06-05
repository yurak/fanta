class CreateNationalTeams < ActiveRecord::Migration[5.2]
  def change
    create_table :national_teams do |t|
      t.string :name, default: '', null: false
      t.string :code, default: '', null: false
      t.string :color, default: 'DB0A23', null: false
      t.integer :status, default: 0, null: false
      t.references :tournament, foreign_key: true

      t.timestamps
    end

    add_reference :players, :national_team, foreign_key: true

    add_index :national_teams, :code, unique: true
    add_index :national_teams, :name, unique: true

    tournament = Tournament.find_or_create_by(
      name: 'Euro 2020',
      code: 'euro'
    )

    TournamentRounds::Creator.call(tournament.id, Season.last.id, count: 22) if tournament

    NationalTeams::Creator.call
  end
end
