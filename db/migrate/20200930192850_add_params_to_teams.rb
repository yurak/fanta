class AddParamsToTeams < ActiveRecord::Migration[5.2]
  def change
    add_column :teams, :code, :string, null: false, default: ''
    add_column :teams, :human_name, :string, null: false, default: ''

    Team.all.reload.each do |team|
      team.update(code: team.name.upcase[0..2], human_name: team.name.titleize[0..18])
    end
  end
end
