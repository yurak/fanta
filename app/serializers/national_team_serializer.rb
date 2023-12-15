class NationalTeamSerializer < ActiveModel::Serializer
  attributes :id
  attributes :code
  attributes :color
  attributes :kit_path
  attributes :name
  attributes :profile_kit_path
  attributes :status
  attributes :tournament_id
end
