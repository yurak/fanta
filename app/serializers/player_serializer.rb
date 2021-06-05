class PlayerSerializer < ActiveModel::Serializer
  attributes :avatar_path, :first_name, :id, :kit_path, :name, :national_kit_path, :national_team_name

  def national_team_name
    object.national_team&.name
  end
end
