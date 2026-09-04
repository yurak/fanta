class AddIncidentsDataToTournamentMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :tournament_matches, :incidents_data, :text
  end
end
