RSpec.describe AuctionBid do
  subject(:auction_bid) { create(:auction_bid) }

  describe 'Associations' do
    it { is_expected.to belong_to(:auction_round).optional }
    it { is_expected.to belong_to(:team) }
    it { is_expected.to have_many(:player_bids).dependent(:destroy) }
  end

  describe 'draft bid (without auction_round)' do
    it 'is valid without auction_round' do
      bid = build(:auction_bid, auction_round: nil)
      expect(bid).to be_valid
    end

    it 'can be created without auction_round' do
      expect { create(:auction_bid, auction_round: nil) }.not_to raise_error
    end
  end
end
