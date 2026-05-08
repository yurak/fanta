class AddIndexToPlayerSeasonStats < ActiveRecord::Migration[6.1]
  def change
    add_index :player_season_stats, %i[player_id season_id club_id], unique: true,
              name: 'index_player_season_stats_on_player_season_club'
  end
end
