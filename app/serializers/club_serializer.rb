class ClubSerializer < ActiveModel::Serializer
  attributes :id
  attributes :code
  attributes :color
  attributes :kit_path
  attributes :logo_path
  attributes :name
  attributes :profile_kit_path
  attributes :status
  attributes :tm_url
  attributes :tournament_id
end
