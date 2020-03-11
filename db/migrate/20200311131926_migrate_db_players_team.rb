class MigrateDbPlayersTeam < ActiveRecord::Migration[5.2]
  def change
    ActiveRecord::Base.transaction do
      Player.where.not(team_id: nil).each do |player|
        next if PlayerTeam.find_by(player_id: player.id, team_id: player.team_id)

        PlayerTeam.create!(player_id: player.id, team_id: player.team_id)
      end
    end
  end
end
