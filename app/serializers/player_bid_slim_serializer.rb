class PlayerBidSlimSerializer < ActiveModel::Serializer
  attributes :id
  attributes :status
  attributes :price
  attributes :team

  def team
    TeamSlimSerializer.new(object.team)
  end
end
