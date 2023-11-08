class TournamentSerializer < ActiveModel::Serializer
  attributes :id
  attributes :icon
  attributes :logo
  attributes :name
  attributes :short_name

  def logo
    ActionController::Base.helpers.asset_path(object.logo_path)
  end
end
