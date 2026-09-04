class AddLiveScoresSupport < ActiveRecord::Migration[8.0]
  def up
    add_column :tournament_matches, :status, :integer, default: 0, null: false
    add_column :national_matches, :status, :integer, default: 0, null: false
    add_column :tournament_matches, :live_minute, :integer
    add_column :national_matches, :live_minute, :integer
    add_column :tournaments, :live_scores_enabled, :boolean, default: false, null: false
    add_column :tournament_rounds, :schedule_refreshed_at, :datetime

    TournamentMatch.where.not(host_score: nil).update_all(status: 2) # rubocop:disable Rails/SkipsModelValidations
    NationalMatch.where.not(host_score: nil).update_all(status: 2) # rubocop:disable Rails/SkipsModelValidations
  end

  def down
    remove_column :tournament_matches, :status
    remove_column :national_matches, :status
    remove_column :tournament_matches, :live_minute
    remove_column :national_matches, :live_minute
    remove_column :tournaments, :live_scores_enabled
    remove_column :tournament_rounds, :schedule_refreshed_at
  end
end
