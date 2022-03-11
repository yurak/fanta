RSpec.describe AuctionBid, type: :model do
  subject(:auction_bid) { create(:auction_bid) }

  describe 'Associations' do
    it { is_expected.to belong_to(:auction_round) }
    it { is_expected.to belong_to(:team) }
    it { is_expected.to have_many(:player_bids).dependent(:destroy) }
  end
end
