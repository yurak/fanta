class RemoveLeagueFields < ActiveRecord::Migration[5.2]
  def change
    remove_column :leagues, :cleansheet_m
    remove_column :leagues, :custom_bonuses
    remove_column :leagues, :failed_penalty
    remove_column :leagues, :missed_goals
    remove_column :leagues, :recount_goals
  end
end
