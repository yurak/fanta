class PlayerSerializer < ActiveModel::Serializer
  attributes :id, :name, :avatar_path, :kit_path

  def name
    object.name.upcase
  end

  def avatar_path
    "/assets/#{ActionController::Base.helpers.resolve_asset_path(object.avatar_path)}"
  end

  def kit_path
    "/assets/#{ActionController::Base.helpers.resolve_asset_path(object.kit_path)}"
  end
end
