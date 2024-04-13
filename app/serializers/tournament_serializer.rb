class TournamentSerializer < ActiveModel::Serializer
  attributes :id
  attributes :icon
  attributes :logo
  attributes :mantra_format
  attributes :name
  attributes :short_name
  attributes :clubs

  def clubs
    return unless instance_options[:clubs]

    clubs = object.fanta? ? object.ec_clubs.active : object.clubs.active
    clubs.map { |club| ClubSerializer.new(club) }
  end

  def logo
    ActionController::Base.helpers.asset_path(object.logo_path)
  end

  def mantra_format
    !object.fanta?
  end
end
