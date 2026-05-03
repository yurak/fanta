class PlayerBidSerializer < ActiveModel::Serializer
  attributes :id
  attributes :status
  attributes :price
  attributes :player
  attributes :auction_bids

  def player
    PlayerBaseSerializer.new(object.player)
  end

  def auction_bids
    object.player.player_bids_by(object.auction_bid.auction.id).each_with_object({}) do |(number, bids), result|
      result[number.to_s] = bids.map { |bid| PlayerBidSlimSerializer.new(bid).as_json }
    end
  end
end
