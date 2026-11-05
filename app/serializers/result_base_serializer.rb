class ResultBaseSerializer < ActiveModel::Serializer
  attributes :id
  attributes :points
  attributes :team_code
  attributes :team_id
  attributes :team_logo
  attributes :team_name

  def team_code
    object.team.code
  end

  def team_id
    object.team.id
  end

  def team_logo
    object.team.logo_path
  end

  def team_name
    object.team.human_name
  end
end
