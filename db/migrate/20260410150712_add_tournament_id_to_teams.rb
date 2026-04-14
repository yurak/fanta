class AddTournamentIdToTeams < ActiveRecord::Migration[6.1]
  def up
    cleanup_orphan_teams
    add_reference :teams, :tournament, null: true, foreign_key: true
    backfill_from_league
    backfill_from_join
    backfill_from_results
  end

  def down
    remove_reference :teams, :tournament, foreign_key: true
  end

  private

  # Delete teams with no meaningful dependencies (equivalent to rake 'teams:cleanup_orphans[false]')
  def cleanup_orphan_teams
    execute <<~SQL.squish
      DELETE FROM teams
      WHERE league_id IS NULL
        AND id NOT IN (SELECT team_id FROM joins)
        AND id NOT IN (SELECT team_id FROM auction_bids)
        AND id NOT IN (SELECT team_id FROM lineups)
        AND id NOT IN (SELECT team_id FROM results)
        AND id NOT IN (SELECT team_id FROM transfers)
        AND id NOT IN (SELECT team_id FROM player_teams)
        AND id NOT IN (SELECT host_id FROM matches)
        AND id NOT IN (SELECT guest_id FROM matches)
    SQL
  end

  def backfill_from_league
    execute <<~SQL.squish
      UPDATE teams SET tournament_id = leagues.tournament_id
      FROM leagues WHERE teams.league_id = leagues.id
    SQL
  end

  def backfill_from_join
    execute <<~SQL.squish
      UPDATE teams SET tournament_id = joins.tournament_id
      FROM joins WHERE joins.team_id = teams.id AND teams.tournament_id IS NULL
    SQL
  end

  def backfill_from_results
    execute <<~SQL.squish
      UPDATE teams SET tournament_id = leagues.tournament_id
      FROM results JOIN leagues ON leagues.id = results.league_id
      WHERE results.team_id = teams.id AND teams.tournament_id IS NULL
    SQL
  end
end
