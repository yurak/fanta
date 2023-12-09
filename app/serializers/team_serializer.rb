class TeamSerializer < ActiveModel::Serializer
  attributes :id
  attributes :budget
  attributes :code
  attributes :human_name
  attributes :league_id
  attributes :logo_path
  attributes :players
  attributes :user_id

  def players
    object.player_teams.pluck(:player_id)
  end
end
