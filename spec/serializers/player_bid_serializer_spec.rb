require 'rails_helper'

RSpec.describe PlayerBidSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(build_player_bid)

      expect(serializer.serializable_hash.keys).to match_array(%i[id status price player auction_bids])
    end
  end

  def build_player_bid
    auction = create(:auction)
    auction_round = create(:auction_round, auction: auction)
    auction_bid = create(:auction_bid, auction_round: auction_round)
    player_bid = create(:player_bid, auction_bid: auction_bid)
    allow(player_bid.player).to receive(:player_bids_by).with(auction.id).and_return({ 1 => [player_bid] })
    player_bid
  end
end
