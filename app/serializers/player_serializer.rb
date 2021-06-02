class PlayerSerializer < ActiveModel::Serializer
  attributes :avatar_path, :first_name, :id, :kit_path, :name, :national_kit_path, :national_team_name

  def kit_path
    "/assets/#{ActionController::Base.helpers.resolve_asset_path(object.kit_path)}"
  end

  def national_kit_path
    "/assets/#{ActionController::Base.helpers.resolve_asset_path(object.national_kit_path)}" if object.national_team
  end

  def national_team_name
    object.national_team&.name
  end
end
