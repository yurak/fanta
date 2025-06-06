class AddSixtiesToPlayerSeasonStats < ActiveRecord::Migration[6.1]
  def change
    add_column :player_season_stats, :sixties, :integer, default: 0, null: false
  end
end
