class ResultSerializer < ActiveModel::Serializer
  attributes :id, :team_name, :points, :goals_difference

  def team_name
    object.team.name.titleize
  end
end
