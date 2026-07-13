class AddSeasonToJoins < ActiveRecord::Migration[8.0]
  def up
    add_column :joins, :season_id, :bigint
    add_index :joins, :season_id

    backfill_seasons

    change_column_null :joins, :season_id, false
    add_foreign_key :joins, :seasons

    remove_index :joins, column: %i[user_id tournament_id], unique: true,
                         name: 'index_joins_on_user_id_and_tournament_id'
    add_index :joins, %i[user_id tournament_id season_id], unique: true,
                                                           name: 'index_joins_on_user_tournament_season'
  end

  def down
    remove_index :joins, name: 'index_joins_on_user_tournament_season'
    add_index :joins, %i[user_id tournament_id], unique: true,
                                                 name: 'index_joins_on_user_id_and_tournament_id'
    remove_foreign_key :joins, :seasons
    remove_index :joins, :season_id
    remove_column :joins, :season_id
  end

  private

  def backfill_seasons
    current = select_value('SELECT id FROM seasons ORDER BY id DESC LIMIT 1')
    return unless current

    previous = select_value('SELECT id FROM seasons ORDER BY id DESC LIMIT 1 OFFSET 1') || current

    execute("UPDATE joins SET season_id = #{previous.to_i} WHERE status IN (2, 3)")
    execute("UPDATE joins SET season_id = #{current.to_i} WHERE season_id IS NULL")
  end
end
