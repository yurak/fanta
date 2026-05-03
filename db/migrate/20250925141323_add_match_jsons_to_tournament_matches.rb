class AddMatchJsonsToTournamentMatches < ActiveRecord::Migration[6.1]
  def change
    add_column :tournament_matches, :base_data, :text
    add_column :tournament_matches, :lineups_data, :text
  end
end
