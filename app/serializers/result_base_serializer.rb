class ResultBaseSerializer < ActiveModel::Serializer
  attributes :id
  attributes :points
  attributes :team_id
  attributes :team_name

  def team_id
    object.team.id
  end

  def team_name
    object.team.human_name
  end
end
