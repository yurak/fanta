class ChangeIndexOnLeaguesNameAndSeasonId < ActiveRecord::Migration[6.1]
  def change
    remove_index :leagues, name: "index_leagues_on_name"

    add_index :leagues, [:name, :season_id], unique: true
  end
end
