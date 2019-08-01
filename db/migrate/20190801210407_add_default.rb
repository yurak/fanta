class AddDefault < ActiveRecord::Migration[5.2]
  def change
    change_column :match_players, :goals, :decimal, default: 0
    change_column :match_players, :missed_goals, :decimal, default: 0
    change_column :match_players, :assits, :decimal, default: 0
    change_column :match_players, :malus, :decimal, default: 0
    change_column :match_players, :bonus, :decimal, default: 0
  end
end
