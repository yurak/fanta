class AllowAuctionWeeklyTeamPlayers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :weekly_team_players, :round_player_id, true
    add_reference :weekly_team_players, :player, null: true, foreign_key: true
    add_column :weekly_team_players, :max_price, :decimal
  end
end
