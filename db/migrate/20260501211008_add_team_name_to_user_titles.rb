class AddTeamNameToUserTitles < ActiveRecord::Migration[6.1]
  def change
    add_column :user_titles, :team_name, :string
  end
end
