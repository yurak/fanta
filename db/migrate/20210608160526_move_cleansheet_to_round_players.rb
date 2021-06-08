class MoveCleansheetToRoundPlayers < ActiveRecord::Migration[5.2]
  def change
    add_column :round_players, :cleansheet, :boolean, default: false

    MatchPlayer.all.each do |mp|
      mp.round_player.update(cleansheet: mp.cleansheet)
    end

    remove_column :match_players, :cleansheet
  end
end
