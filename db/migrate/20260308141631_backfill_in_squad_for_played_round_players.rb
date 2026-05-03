class BackfillInSquadForPlayedRoundPlayers < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      UPDATE round_players
      SET in_squad = TRUE
      WHERE played_minutes > 0 OR score > 0
    SQL
  end

  def down; end
end
