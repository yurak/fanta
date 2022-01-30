RSpec.describe AuctionRound, type: :model do
  # subject(:auction_round) { create(:auction_round) }

  describe 'Associations' do
    it { is_expected.to belong_to(:auction) }
  end
end
