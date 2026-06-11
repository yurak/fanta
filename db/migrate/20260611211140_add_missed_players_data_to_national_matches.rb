class AddMissedPlayersDataToNationalMatches < ActiveRecord::Migration[6.1]
  def change
    add_column :national_matches, :missed_players_data, :text
  end
end
