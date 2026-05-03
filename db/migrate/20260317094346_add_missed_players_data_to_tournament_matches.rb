class AddMissedPlayersDataToTournamentMatches < ActiveRecord::Migration[6.1]
  def change
    add_column :tournament_matches, :missed_players_data, :text
  end
end
