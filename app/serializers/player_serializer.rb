class PlayerSerializer < ActiveModel::Serializer
  attributes :avatar_path, :club_code, :first_name, :id, :kit_path, :name, :national_kit_path, :national_team_name, :position_names

  def national_team_name
    object.national_team&.name
  end

  def club_code
    object.club&.code
  end
end
