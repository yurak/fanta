class ChangeAvgDefScoreDefaults < ActiveRecord::Migration[6.1]
  def change
    change_column_default :leagues, :min_avg_def_score, from: 6.0, to: 7.0
    change_column_default :leagues, :max_avg_def_score, from: 7.0, to: 8.0
  end
end
