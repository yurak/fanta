class AddParamsToLeague < ActiveRecord::Migration[5.2]
  def change
    add_column :leagues, :min_avg_def_score, :decimal, null: false, default: Lineup::MIN_AVG_DEF_SCORE
    add_column :leagues, :max_avg_def_score, :decimal, null: false, default: Lineup::MAX_AVG_DEF_SCORE
    add_column :leagues, :custom_bonuses, :boolean, null: false, default: false
    add_column :leagues, :missed_goals, :decimal, null: false, default: 2.0
    add_column :leagues, :failed_penalty, :decimal, null: false, default: 3.0
  end
end
