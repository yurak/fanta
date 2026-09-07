class DedupRoundPlayers < ActiveRecord::Migration[8.0]
  INDEX_NAME = 'index_round_players_on_tournament_round_id_and_player_id'.freeze

  def up
    duplicated_pairs.each { |round_id, player_id| merge(round_id, player_id) }

    add_index :round_players, %i[tournament_round_id player_id], unique: true, name: INDEX_NAME
  end

  def down
    remove_index :round_players, name: INDEX_NAME
  end

  private

  def duplicated_pairs
    select_rows(<<~SQL.squish)
      SELECT tournament_round_id, player_id FROM round_players
      GROUP BY tournament_round_id, player_id HAVING COUNT(*) > 1
    SQL
  end

  # The row that actually carries the score wins; ties go to the one most lineups already point at.
  def merge(round_id, player_id)
    ids = select_values(<<~SQL.squish)
      SELECT rp.id FROM round_players rp
      WHERE rp.tournament_round_id = #{round_id} AND rp.player_id = #{player_id}
      ORDER BY rp.score DESC,
               (SELECT COUNT(*) FROM match_players mp WHERE mp.round_player_id = rp.id) DESC,
               rp.id ASC
    SQL
    keeper, *losers = ids
    losers.each { |loser| absorb(keeper, loser) }
    say "round #{round_id}, player #{player_id}: kept #{keeper}, merged #{losers.join(', ')}"
  end

  def absorb(keeper, loser)
    drop_conflicting_match_players(keeper, loser)

    execute "UPDATE match_players SET round_player_id = #{keeper} WHERE round_player_id = #{loser}"
    execute "UPDATE substitutes SET out_rp_id = #{keeper} WHERE out_rp_id = #{loser}"
    execute "UPDATE substitutes SET in_rp_id = #{keeper} WHERE in_rp_id = #{loser}"
    execute "UPDATE weekly_team_players SET round_player_id = #{keeper} WHERE round_player_id = #{loser}"
    execute "DELETE FROM round_players WHERE id = #{loser}"
  end

  # A lineup can hold both rows (Tours::LineupGenerator adds a "not in squad" entry per round player),
  # and the merge would leave it with the same player twice. Keep the entry that carries the bigger
  # role — a starting slot first, then anything that is not "not in squad" (subs_status 3).
  def drop_conflicting_match_players(keeper, loser)
    select_values(<<~SQL.squish).each { |lineup_id| drop_weaker_match_player(keeper, loser, lineup_id) }
      SELECT lineup_id FROM match_players WHERE round_player_id = #{loser}
      INTERSECT
      SELECT lineup_id FROM match_players WHERE round_player_id = #{keeper}
    SQL
  end

  def drop_weaker_match_player(keeper, loser, lineup_id)
    doomed = select_values(<<~SQL.squish).drop(1)
      SELECT id FROM match_players
      WHERE lineup_id = #{lineup_id} AND round_player_id IN (#{keeper}, #{loser})
      ORDER BY (real_position IS NULL), (subs_status = 3), id
    SQL
    return if doomed.empty?

    execute "DELETE FROM substitutes WHERE main_mp_id IN (#{doomed.join(',')}) OR reserve_mp_id IN (#{doomed.join(',')})"
    execute "DELETE FROM match_players WHERE id IN (#{doomed.join(',')})"
  end
end
