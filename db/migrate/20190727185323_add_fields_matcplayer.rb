class AddFieldsMatcplayer < ActiveRecord::Migration[5.2]
  def change
    add_column :match_players, :red_card, :boolean, default: false
    add_column :match_players, :yellow_card, :boolean, default: false
    add_column :match_players, :cleansheet, :boolean, default: false
    add_column :match_players, :goals, :decimal
    add_column :match_players, :missed_goals, :decimal
    add_column :match_players, :assits, :decimal
    add_column :match_players, :malus, :decimal
    add_column :match_players, :bonus, :decimal
  end
end
