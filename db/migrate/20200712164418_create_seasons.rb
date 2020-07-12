class CreateSeasons < ActiveRecord::Migration[5.2]
  def change
    create_table :seasons do |t|
      t.integer :start_year
      t.integer :end_year

      t.timestamps
    end

    add_reference :leagues, :season, foreign_key: true

    season = Season.create(start_year: Season::MIN_START_YEAR, end_year: Season::MIN_END_YEAR)
    League.all.each { |league| league.update(season: season)}
  end
end
