class AddLiveScoresSupport < ActiveRecord::Migration[8.0]
  def up
    # 0 = scheduled, 1 = live, 2 = finished
    add_column :tournament_matches, :status, :integer, default: 0, null: false
    add_column :national_matches, :status, :integer, default: 0, null: false
    add_column :tournaments, :live_scores_enabled, :boolean, default: false, null: false
    # stamped once a round's real kickoff times have been pulled from the source, so the
    # schedule refresher scrapes each opened round only once
    add_column :tournament_rounds, :schedule_refreshed_at, :datetime

    # existing matches that already carry a score are finished
    TournamentMatch.where.not(host_score: nil).update_all(status: 2) # rubocop:disable Rails/SkipsModelValidations
    NationalMatch.where.not(host_score: nil).update_all(status: 2) # rubocop:disable Rails/SkipsModelValidations
  end

  def down
    remove_column :tournament_matches, :status
    remove_column :national_matches, :status
    remove_column :tournaments, :live_scores_enabled
    remove_column :tournament_rounds, :schedule_refreshed_at
  end
end
