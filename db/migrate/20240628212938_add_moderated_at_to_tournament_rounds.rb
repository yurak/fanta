class AddModeratedAtToTournamentRounds < ActiveRecord::Migration[6.1]
  def change
    add_column :tournament_rounds, :moderated_at, :datetime
  end
end
