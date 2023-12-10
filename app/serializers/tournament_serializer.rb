class TournamentSerializer < ActiveModel::Serializer
  attributes :id
  attributes :icon
  attributes :logo
  attributes :mantra_format
  attributes :name
  attributes :short_name

  def logo
    ActionController::Base.helpers.asset_path(object.logo_path)
  end

  def mantra_format
    !object.fanta?
  end
end
