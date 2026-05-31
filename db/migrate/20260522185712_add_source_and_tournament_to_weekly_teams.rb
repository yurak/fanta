class AddSourceAndTournamentToWeeklyTeams < ActiveRecord::Migration[6.1]
  def change
    add_column :weekly_teams, :source, :string, default: 'round', null: false
    add_reference :weekly_teams, :tournament, null: true, foreign_key: true
  end
end
